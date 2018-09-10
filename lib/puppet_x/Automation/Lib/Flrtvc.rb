require 'pathname'
require 'open-uri'
require 'openssl'
require 'fileutils'
require 'net/http'
require 'net/https'
require 'net/ftp'
require 'csv'
require 'open3'
require_relative './Remote/c_rsh.rb'
require_relative './Log.rb'
require_relative './Nim.rb'
require_relative './Utils.rb'

module Automation
  module Lib
    # ##########################################################################
    #  Class Flrtvc
    # ##########################################################################
    class Flrtvc
      attr_reader :root # String
      attr_reader :targets # String,

      # ########################################################################
      # name : initialize
      # param :input:args:arrays of strings
      #  args[0]:targets:string coma separated list of targets
      #  args[1]:string root
      #  arsg[2]:steps:string ['Status',RunFlrtvc','ParseFlrtvc',
      #     'DownloadFixes', 'CheckFixes','BuildResource','InstallResource']
      #     , default InstallResource
      #  arsg[3]:level:string ['sec', 'hiper', 'all', nil], default: all
      #  arsg[4]:force:string ['yes', 'no'], default: no
      #
      # return :
      # description : instantiate Flrtvc request
      # ########################################################################
      def initialize(args)
        #
        if !args.empty?
          targets = args[0]
          @targets = targets.split(',')
        else
          @targets = ''
        end
        #
        if args.size > 1
          if !args[1].nil? && !args[1].empty?
            root = args[1]
            @root_dir = if root =~ %r{^\/}
                          root
                        else
                          Dir.pwd + '/' + root
                        end
            # Check root directory
            Utils.check_directory(@root_dir)
          else
            @root = ''
          end
        end
        #
        if args.size > 4
          step = args[2]
          level = args[3]
          force = args[4]
          @step = step
          @level = level
          @force = force.to_s
        else
          @step = ''
          @level = ''
          @force = 'yes'
        end
        #
        Log.log_info("Flrtvc constructor @targets=#{@targets} \
@root=#{@root} @step=#{@step} @level=#{@level} @force=#{@force}")

        if @force == 'yes'
          #
          # to keep in memory the already parsed fixes
          # so that they are not parsed again and again
          #
          @lppminmax_of_fixes = {}
          #
          # to keep in memory the list of fixes per url
          #  so that we can build the list of fix for each target,
          #  even if the url has already been downloaded
          #
          @listoffixes_per_url = {}
        else
          #
          # to keep in memory the already parsed fixes
          # so that they are not parsed again and again
          #
          lppminmax_of_fixes_yml_file = get_flrtvc_name(:YML,
                                                        'all',
                                                        'lppminmax_of_fixes')
          if File.exist?(lppminmax_of_fixes_yml_file)
            @lppminmax_of_fixes = YAML.load_file(lppminmax_of_fixes_yml_file)
            Log.log_debug('Reading from ' +
                              lppminmax_of_fixes_yml_file +
                              ' @lppminmax_of_fixes.length=' +
                              @lppminmax_of_fixes.length.to_s)
          else
            @lppminmax_of_fixes = {}
            Log.log_debug(' @lppminmax_of_fixes.length=' +
                              @lppminmax_of_fixes.length.to_s)
          end
          #
          # to keep in memory the list of fixes per url
          #  so that we can build the list of fix for each target,
          #  even if the url has already been downloaded
          #
          listoffixes_per_url_yml_file = get_flrtvc_name(:YML,
                                                         'all',
                                                         'all_listoffixes_per_url')
          if File.exist?(listoffixes_per_url_yml_file)
            @listoffixes_per_url = YAML.load_file(listoffixes_per_url_yml_file)
            Log.log_debug('Reading from ' +
                              listoffixes_per_url_yml_file +
                              ' @listoffixes_per_url.length=' +
                              @listoffixes_per_url.length.to_s)
          else
            @listoffixes_per_url = {}
            Log.log_debug(' @listoffixes_per_url.length=' +
                              @listoffixes_per_url.length.to_s)
          end
        end
      end

      # ########################################################################
      # name : check_flrtvc
      # param :
      # return :
      # description : no need to explain
      #  but not used
      # ########################################################################
      def check_flrtvc
        raise FlrtvcNotFound unless ::File.exist?('/usr/bin/flrtvc.ksh')
      end

      # ########################################################################
      # name : get_flrtvc_name
      # param : input:type:symbol
      #   either :AdvisoryFlrtvc
      #   or :AdvisoryURLs
      #   or :DownloadURLs
      #   or :common_efixes :temp_dir
      #   or :efixes
      #   or :emgr
      #   or :filesets
      #   or :flrtvc
      #   or :lslpp
      #   or :NIM_dir
      #   or :NIM_res
      #   or :URL
      #   or :YML
      #   or any string
      #
      # param : input:target:string       not for :common_efixes :temp_dir
      # param : input:name_suffix:string  only for some type (:efixes, )
      # return : dir name, or nim resource name, or file name
      # description : common function to build full path name according to
      #  specific rules to each type.
      # ########################################################################
      def get_flrtvc_name(type,
                          target = '',
                          name_suffix = '')
        #
        # Log.log_debug('get_flrtvc_name type=' + type.to_s + ' target=' +
        #                  target.to_s + ' name_suffix=' + name_suffix.to_s)
        case type
        when :temp_dir
          returned = ::File.join(@root_dir,
                                 'temp')
          # check it exist
          Utils.check_directory(returned)
          # clean it
          FileUtils.rm_rf Dir.glob("#{returned}/*")
        when :tar_dir
          returned = ::File.join(@root_dir,
                                 'tar_dir')
          Utils.check_directory(returned)
        when :tempftp_download
          returned = ::File.join(@root_dir,
                                 'tempftp_download')
          Utils.check_directory(returned)
        when :common_efixes
          returned = ::File.join(@root_dir,
                                 'common_efixes')
          Utils.check_directory(returned)
        when :efixes
          returned = ::File.join(Constants.output_dir,
                                 'flrtvc')
          Utils.check_directory(returned)
          returned = ::File.join(returned,
                                 "#{target}_#{name_suffix}")
        when :emgr
          returned = ::File.join(Constants.output_dir,
                                 'flrtvc')
          Utils.check_directory(returned)
          returned = ::File.join(returned,
                                 "#{target}_emgr.txt")
        when :filesets
          returned = ::File.join(Constants.output_dir,
                                 'flrtvc')
          Utils.check_directory(returned)
          returned = ::File.join(returned,
                                 "#{target}_filesets.txt")
        when :flrtvc
          returned = ::File.join(Constants.output_dir,
                                 'flrtvc')
          Utils.check_directory(returned)
          returned = ::File.join(returned,
                                 "#{target}_flrtvc.csv")
        when :lslpp
          returned = ::File.join(Constants.output_dir,
                                 'flrtvc')
          Utils.check_directory(returned)
          returned = ::File.join(returned,
                                 "#{target}_lslpp.txt")
        when :NIM_dir
          returned = ::File.join(@root_dir,
                                 "#{target}_NIM",
                                 'emgr',
                                 'ppc')
          Utils.check_directory(returned)
        when :NIM_res
          returned = "PAA_FLRTVC_#{target}"
        when :URL
          returned = ::File.join(Constants.output_dir,
                                 'flrtvc')
          Utils.check_directory(returned)
          returned = ::File.join(returned,
                                 "#{target}_URL.txt")
        when :YML
          returned = ::File.join(Constants.output_dir,
                                 'flrtvc')
          Utils.check_directory(returned)
          returned = if name_suffix == 'lppminmax_of_fixes'
                       ::File.join(returned,
                                   "#{name_suffix}.yml")
                     elsif name_suffix == 'all_listoffixes_per_url'
                       ::File.join(returned,
                                   "#{name_suffix}.yml")
                     else
                       ::File.join(returned,
                                   "#{target}_#{name_suffix}.yml")
                     end
        else
          returned = ::File.join(Constants.output_dir,
                                 'flrtvc')
          Utils.check_directory(returned)
          returned = ::File.join(returned,
                                 type + "_#{target}.txt")
        end
        # Log.log_debug('get_flrtvc_name returning ' + returned)
        returned
      end

      # ########################################################################
      # name : mine_this_step
      # param : input:step:string current step being done, to log it
      # param : input:target:string one particular target on which
      #   action is being done
      #
      # return : hash with false as key and yml content as value,
      #  or with true as key and nil as value.
      # description : if true is returned as key, it means that the mining
      #   must be done.
      # ########################################################################
      def mine_this_step(step,
                         target)
        Log.log_debug('Into mine_this_step (target=' + target + \
') step=' + step.to_s + ' force=' + @force.to_s)
        returned = {}
        target_yml_file = get_flrtvc_name(:YML, target, step)
        #
        if @force == 'yes'
          Log.log_debug('Into mine_this_step  removing ' + target_yml_file)
          File.delete(target_yml_file) if File.exist?(target_yml_file)
        else
          Log.log_debug('Into mine_this_step  keeping ' + target_yml_file)
        end
        #
        begin
          yml_output = YAML.load_file(target_yml_file)
          if yml_output.nil?
            returned[true] = nil
          elsif yml_output.empty?
            returned[true] = nil
          else
            returned[false] = yml_output
          end
        rescue StandardError
          returned[true] = nil
        end
        returned
      end

      # ########################################################################
      # name : run_step
      # param : input:step:string current step being done, to log it
      # param : input:target:string one particular target on which
      #   action is being done
      # param : input:param: specific param for this step
      #
      # return : depending on the step
      # description : switch function, to call specific function for each step.
      # ########################################################################
      def run_step(step,
                   target,
                   param = '')
        # Log.log_debug('Into run_step(' + step.to_s + ', ' +
        #                  target + ', ' + param.to_s + ')')
        case step
        when :status
          returned = step_status(step, target, param)
        when :installFlrtvc
          returned = step_install_flrtvc(step)
        when :runFlrtvc
          returned = step_run_flrtvc(step, target)
        when :parseFlrtvc
          returned = step_parse_flrtvc(step, target, param)
        when :downloadFixes
          returned = step_perform_downloads(step, target, param)
        when :checkFixes
          returned = step_check_fixes(step, target, param)
        when :buildResource
          returned = step_build_nim_resource(step, target, param)
        when :installFixes
          returned = step_install_fixes(step, target, param)
        when :removeFixes
          returned = step_remove_fixes(step, target)
        else
          Log.log_err('Unknown step ' + step.to_s)
          returned = ''
        end
        returned
      end

      # ########################################################################
      # name : step_status
      # param : input:step:string current step being done, to log it
      # param : input:target:string one particular target on
      #   which action is being done
      # param : input:yaml_file_name:yaml file name to persist output,
      #  if no param is provided, output is not persisted.
      # return : status of the target
      # description : please note this step is as well done and
      #  integrated into the 'standalones' factor
      # ########################################################################
      def step_status(step,
                      target,
                      yaml_file_name = '')
        Log.log_info('Flrtvc step : ' + step.to_s + ' (target=' + target + ')')
        status_output = Utils.status(target)
        status_output.keys.each do |key|
          Log.log_info(' ' + key + '=>' + status_output[key])
        end

        if !status_output.nil? &&
            !status_output.empty? &&
            !yaml_file_name.nil? &&
            !yaml_file_name.empty?
          # Persist to yml
          status_yml_dir = ::File.join(Constants.output_dir,
                                       'flrtvc')
          Utils.check_directory(status_yml_dir)
          status_yml_file = ::File.join(status_yml_dir,
                                        yaml_file_name)
          File.write(status_yml_file, status_output.to_yaml)
          Log.log_info('Refer to "' + status_yml_file + '" to have status of "fix" ("flrtvc" provider)')
        end
      end

      # ########################################################################
      # name : step_install_flrtvc
      # param : input:step:string current step being done, to log it
      # return : 0 if everything is ok
      # description : step to install flrtvc if it is not installed.
      # ########################################################################
      def step_install_flrtvc(step)
        Log.log_debug('Into step ' + step.to_s)
        Utils.check_install_flrtvc
      end

      # ########################################################################
      # name : step_run_flrtvc
      # param : input:step:string current step being done, to log it
      # param : input:target:string one particular target on
      #   which action is being done
      # return : array of flrtvc output (either from yml output, or
      #   from flrtvc command)
      # description : gathers all elements (output of lslpp, output of emgr)
      #   to be able to run flrtvc.ksh and runs it, persists output of this
      #   command into yml file particular for this target. If the yml already
      #   exists, take the yml file.
      # ########################################################################
      def step_run_flrtvc(step,
                          target)
        Log.log_info('Flrtvc step : ' + step.to_s + ' (target=' + target + ')')
        mine_this_step_hash = mine_this_step(step, target)
        if mine_this_step_hash[false].nil?
          Log.log_debug('Doing mine_this_step (target=' + target +
                            ') step=' + step.to_s)
          #
          lslpp_file = get_flrtvc_name(:lslpp, target)
          Log.log_debug(' lslpp_file=' + lslpp_file)
          #
          url_file = get_flrtvc_name(:URL, target)
          Log.log_debug(' url_file=' + url_file)
          #
          emgr_file = get_flrtvc_name(:emgr, target)
          Log.log_debug(' emgr_file=' + emgr_file)
          #
          flrtvc_file = get_flrtvc_name(:flrtvc, target)
          Log.log_debug(' flrtvc_file=' + flrtvc_file)
          #
          # TODO : 'master' target is not supported consistently so far
          if target == 'master'
            #
            cmd1 = "/usr/bin/lslpp -Lcq > #{lslpp_file}"
            Utils.execute(cmd1)
            #
            cmd2 = "/usr/sbin/emgr -lv3 > #{emgr_file}"
            Utils.execute(cmd2)
          else
            #
            cmd1 = '/usr/bin/lslpp -Lcq'
            lslpp_output = ''
            remote_cmd_rc = Remote.c_rsh(target, cmd1, lslpp_output)
            if remote_cmd_rc == 0
              File.open(lslpp_file, 'w') { |file| file.write(lslpp_output) }
              Log.log_debug(' lslpp_file ' + lslpp_file + ' written')
            end
            #
            cmd2 = '/usr/sbin/emgr -lv3'
            emgr_output = ''
            remote_cmd_rc = Remote.c_rsh(target, cmd2, emgr_output)
            if remote_cmd_rc == 0
              File.open(emgr_file, 'w') { |file| file.write(emgr_output) }
              Log.log_debug(' emgr_file ' + emgr_file + ' written')
            end
          end
          #
          cmd = if @level != :all
                  "/usr/bin/flrtvc.ksh -l #{lslpp_file} -e #{emgr_file} \
-t #{@level}" # {apar_s} {filesets_s} {csv_s}
                else
                  "/usr/bin/flrtvc.ksh -l #{lslpp_file} -e #{emgr_file}" \
 # {apar_s} {filesets_s} {csv_s}
                end
          #
          flrtvc_command_output = []
          Utils.execute2(cmd, flrtvc_command_output)
          # persist to yaml
          target_yml_file = get_flrtvc_name(:YML, target, step)
          File.write(target_yml_file, flrtvc_command_output[0].to_yaml)
          flrtvc_output = flrtvc_command_output[0]
        else
          Log.log_debug('NOT Doing mine_this_step (target=' + target +
                            ') step=' + step.to_s)
          flrtvc_output = mine_this_step_hash[false]
        end
        flrtvc_output
      end

      # ########################################################################
      # name : step_parse_flrtvc
      # param : input:step:string current step being done, to log it
      # param : input:target:string one particular target on
      #   which action is being done
      # param : input:flrtvc_report:string
      # return : urls of fixes
      # description : parse output file generated by flrtvc
      #  for this particular target, to retrieve all URLs of fixes,
      #  generates some files to keep information.
      # ########################################################################
      def step_parse_flrtvc(step,
                            target,
                            flrtvc_report)
        Log.log_info('Flrtvc step : ' + step.to_s + ' (target=' + target + ')')
        #
        mine_this_step_hash = mine_this_step(step, target)
        if mine_this_step_hash[false].nil?
          Log.log_debug('Doing mine_this_step (target=' + target +
                            ') step=' + step.to_s)

          array_of_fixes = CSV.parse(flrtvc_report, headers: true, col_sep: '|')
          #
          # catch all download URLs which are in column with 'Download URL' header
          h_download_urls = {}
          download_urls = []
          advisories = []
          advisory_urls = []
          filesets = []
          array_of_fixes.each do |fix|
            fileset = fix['Fileset']
            filesets << fileset
            #
            download_url = fix['Download URL']
            if !download_url.nil?
              if download_url.eql?('See advisory')
                advisory_url = fix['Bulletin URL']
                advisories << fix.to_s
                advisory_urls << advisory_url
              else
                Log.log_debug(' download_url=' + download_url)
                if download_url =~ \
                   %r{^(http|https|ftp)://(aix.software.ibm.com|public.dhe.ibm.com)/(aix/ifixes/.*?/|aix/efixes/security/.*?.tar)$}
                  download_urls << download_url
                  h_download_urls[download_url] = fileset
                end
              end
            else
              Log.log_debug(' download_url=nil')
            end
          end
          filesets.uniq!
          filesets.sort!
          #
          Log.log_info(' For ' + target + ", we found #{h_download_urls.size} \
different download links over #{array_of_fixes.size} vulnerabilities \
and #{filesets.size} filesets.")
          #
          advisory_target_yml_file = get_flrtvc_name(:YML,
                                                     target,
                                                     :AdvisoryFlrtvc)
          File.write(advisory_target_yml_file, advisories.to_yaml)
          Log.log_info(' See list of advisories mentionned by flrtvc into ' +
                           advisory_target_yml_file)
          advisory_urls_target_yml_file = get_flrtvc_name(:YML,
                                                          target,
                                                          :AdvisoryURLs)
          File.write(advisory_urls_target_yml_file, advisory_urls.to_yaml)
          Log.log_info(' See list of advisory URLs mentionned by flrtvc into ' +
                           advisory_urls_target_yml_file)
          #
          download_urls.uniq!
          download_urls.sort!
          download_urls.reverse!
          #
          # persist to yaml
          target_yml_file = get_flrtvc_name(:YML, target, step)
          File.write(target_yml_file, download_urls.to_yaml)
        else
          Log.log_debug('NOT Doing mine_this_step (target=' + target +
                            ') step=' + step.to_s)
          download_urls = mine_this_step_hash[false]
        end
        download_urls
      end

      # ########################################################################
      # name : step_perform_downloads
      # param : input:step:string current step being done, to log it
      # param : input:target:string one particular target
      #   on which action is being done
      # param : input:urls_of_target:urls
      # return : listoffixes
      # description :
      #  First download is organized, and shared among all targets
      #   URLs can follow several formats, for example :
      #    ftp://aix.software.ibm.com/aix/efixes/security/bellmail_fix.tar
      #    https://aix.software.ibm.com/aix/efixes/security/bind9_fix8.tar
      #    http://aix.software.ibm.com/aix/ifixes/iv97772/
      #    https://aix.software.ibm.com/aix/ifixes/iv75031/
      #   URLs are followed and download is organized at best : all files
      #    already downloaded are not downloaded again.
      # ########################################################################
      def step_perform_downloads(step,
                                 target,
                                 urls_of_target)
        Log.log_info('Flrtvc step : ' + urls_of_target.length.to_s + ' ' + step.to_s + ' (target=' + target + ')')

        urls_of_target.each do |url_of_target|
          Log.log_debug(' url=' + url_of_target.to_s)
        end
        #
        mine_this_step_hash = mine_this_step(step, target)
        if mine_this_step_hash[false].nil?
          Log.log_debug('Doing mine_this_step (target=' + target +
                            ') step=' + step.to_s +
                            ' building now list of fixes for this target')
          total = urls_of_target.length
          index = 0
          efixes_and_downloadstatus = {}
          #
          urls_of_target.each do |url|
            index += 1
            listoffixes_already_downloaded = @listoffixes_per_url[url]
            if listoffixes_already_downloaded.nil?
              Log.log_debug('Into step_perform_downloads (target=' +
                                target +
                                ') download url=' +
                                url + ' not yet downloaded.')
              efixes_and_status_of_url = download_fct(target,
                                                      url,
                                                      index,
                                                      total)
              Log.log_debug('Into step_perform_downloads (target=' +
                                target +
                                ') download url=' +
                                url +
                                ' efixes_and_status_of_url=' +
                                efixes_and_status_of_url.to_s)
              @listoffixes_per_url[url] = efixes_and_status_of_url.keys
            else
              Log.log_debug('Into step_perform_downloads (target=' +
                                target +
                                ') download url=' +
                                url + ' already downloaded.')
              efixes_and_status_of_url = {}
              listoffixes_already_downloaded.each { |x| efixes_and_status_of_url[x] = 0 }
              Log.log_debug('Into step_perform_downloads (target=' +
                                target +
                                ') download url=' +
                                url +
                                ' efixes_and_status_of_url=' +
                                efixes_and_status_of_url.to_s)
            end
            efixes_and_downloadstatus = efixes_and_downloadstatus.merge(efixes_and_status_of_url)
          end
          #
          # persist @listoffixes_per_url
          listoffixes_per_url_yml_file = get_flrtvc_name(:YML,
                                                         'all',
                                                         'listoffixes_per_url')
          Log.log_debug('Persisting into ' +
                            listoffixes_per_url_yml_file +
                            ' @listoffixes_per_url.length=' +
                            @listoffixes_per_url.length.to_s)
          File.write(listoffixes_per_url_yml_file, @listoffixes_per_url.to_yaml)

          #
          counter = efixes_and_downloadstatus.values.count { |v| v }
          Log.log_debug('Into step_perform_downloads (target=' + target +
                            ') efixes_and_downloadstatus=' + efixes_and_downloadstatus.to_s +
                            ' counter=' + counter.to_s)
          #
          listoffixes_missing = efixes_and_downloadstatus.select { |_key, value| value == -1 }
          listoffixes_missing.each do |fix_missing|
            Log.log_err(' Error : download issue for ' + fix_missing.to_s)
          end
          #
          listoffixes_got = efixes_and_downloadstatus.reject { |_key, value| value == -1 }
          listoffixes_got.each do |fix_got|
            Log.log_info(' Success : downloaded fix ' + fix_got.to_s)
          end
          #
          listoffixes = listoffixes_got.keys
          listoffixes.sort!
          listoffixes.reverse!
          #
          # persist to yaml
          target_yml_file = get_flrtvc_name(:YML, target, step)
          File.write(target_yml_file, listoffixes.to_yaml)
        else
          Log.log_debug('NOT Doing mine_this_step (target=' +
                            target +
                            ') step=' +
                            step.to_s)
          listoffixes = mine_this_step_hash[false]
        end
        Log.log_info('Flrtvc step end : ' + listoffixes.length.to_s + ' available fixes (target=' + target + ')')
        listoffixes.each do |fix|
          Log.log_debug(' fix=' + fix.to_s)
        end
        listoffixes
      end

      # ########################################################################
      # name : step_check_fixes
      # param : input:step:string current step being done, to log it
      # param : input:target:string one particular target
      #   on which action is being done
      # param : input:listoffixes:array of string
      # return : listofkeptfixes_of_target
      # description :
      #  Check of fixes is organized, so that only fixes which can be applied
      #    are kept for each target.
      # ########################################################################
      def step_check_fixes(step,
                           target,
                           listoffixes)
        Log.log_info('Flrtvc step : ' + step.to_s + ' (target=' + target + ')')
        #
        mine_this_step_hash = mine_this_step(step, target)
        packaging_date_of_fixes = {}
        if mine_this_step_hash[false].nil?
          Log.log_debug('Doing mine_this_step (target=' + target +
                            ') checking now prerequisites for this listoffixes')
          # Check level prereq
          common_efixes_dirname = get_flrtvc_name(:common_efixes)
          listofkeptfixes = []
          #
          efix_ct_for_this_target = 0
          efix_nb_for_this_target = listoffixes.length
          #
          lppminmax_of_fixes_hash = mine_this_step('lppminmax_of_fixes',
                                                   'all')

          @lppminmax_of_fixes = if lppminmax_of_fixes_hash[false].nil?
                                  {}
                                else
                                  lppminmax_of_fixes_hash[false]
                                end
          #
          Log.log_info('Flrtvc step : ' + step.to_s + ' (target=' + target + ')' +
                           ' Starting with ' + @lppminmax_of_fixes.length.to_s +
                           ' lppminmax_of_fixes') if @lppminmax_of_fixes.length > 0
          @lppminmax_of_fixes.each do |lppminmax_of_fix|
            Log.log_debug('  ' + lppminmax_of_fix.to_s)
          end
          #
          listoffixes.each do |fix|
            Log.log_debug('Flrtvc step : ' + step.to_s + ' (target=' + target + ') fix=' + fix)
            efix_ct_for_this_target += 1
            existing_lppminmax_of_fixes = @lppminmax_of_fixes[fix]
            lpps_minmax_of_fix = {}
            if existing_lppminmax_of_fixes.nil? || existing_lppminmax_of_fixes.empty?
              # If not found, we parse the fix to get all lpp, min, max
              #   (one fix may contain several lpps)
              lpps_minmax_of_fix = min_max_level_prereq_of(::File.join(common_efixes_dirname,
                                                                       fix))
              if !lpps_minmax_of_fix.nil? && !lpps_minmax_of_fix.empty?
                @lppminmax_of_fixes[fix] = lpps_minmax_of_fix
              end
            else
              Log.log_debug('  Existing lppminmax_of_fixes=' +
                                existing_lppminmax_of_fixes.to_s)
              # If found, we take the already found values
              lpps_minmax_of_fix = existing_lppminmax_of_fixes
            end
            #
            # Then we check against the lpp level of this target
            kept_fix_for_this_target = true
            unless lpps_minmax_of_fix.empty?
              lpps_minmax_of_fix.keys.each do |lpp|
                (min, max) = lpps_minmax_of_fix[lpp]
                if level_prereq_ok?(target, lpp, min, max)
                else
                  Log.log_info('Flrtvc step : ' + step.to_s + ' (target=' + target + ')' +
                                   ' fix=' + fix +
                                   ' (' + efix_ct_for_this_target.to_s + '/' +
                                   efix_nb_for_this_target.to_s + ') cannot be applied.')
                  kept_fix_for_this_target = false
                  break
                end
              end
            end
            #
            next unless kept_fix_for_this_target
            Log.log_info('Flrtvc step : ' + step.to_s + ' (target=' + target + ')' +
                             ' fix=' + fix +
                             ' (' + efix_ct_for_this_target.to_s + '/' +
                             efix_nb_for_this_target.to_s + ') can be applied.')
            listofkeptfixes << fix
          end
          #
          Log.log_info('Flrtvc step : ' + listofkeptfixes.length.to_s + ' ' + step.to_s + ' (target=' + target + ')')
          listofkeptfixes.each do |keptfix|
            Log.log_info(' ' + keptfix)
          end
          #
          # persist to yaml the matching between fixes/lpp/min&max
          lppminmax_of_fixes_yml_file = get_flrtvc_name(:YML,
                                                        'all',
                                                        'lppminmax_of_fixes')
          Log.log_debug(' Persisting into ' +
                            lppminmax_of_fixes_yml_file +
                            ' @lppminmax_of_fixes.length=' +
                            @lppminmax_of_fixes.length.to_s)
          File.write(lppminmax_of_fixes_yml_file, @lppminmax_of_fixes.to_yaml)
          #
          # Sort the fixes by packaging date
          Log.log_info(' Into step_check_fixes (target=' + target +
                           ') Sort the fixes by packaging date')
          listofkeptfixes.each do |keptfix|
            packaging_date = packaging_date_of(::File.join(common_efixes_dirname,
                                                           keptfix))
            packaging_date_of_fixes[packaging_date] = keptfix
          end
          packaging_date_of_fixes = packaging_date_of_fixes.sort.to_h
          packaging_date_of_fixes = packaging_date_of_fixes.sort.reverse.to_h
          #
          # persist to yaml match between fix and packaging date
          target_yml_file = get_flrtvc_name(:YML, target, step)
          File.write(target_yml_file, packaging_date_of_fixes.to_yaml)
        else
          Log.log_debug('NOT Doing mine_this_step for target=' +
                            target +
                            ' step=' +
                            step.to_s)
          packaging_date_of_fixes = mine_this_step_hash[false]
          packaging_date_of_fixes = packaging_date_of_fixes.sort.to_h
          packaging_date_of_fixes = packaging_date_of_fixes.sort.reverse.to_h
        end
        #
        Log.log_debug('Flrtvc step : ' + packaging_date_of_fixes.length.to_s + ' ' + step.to_s + ' (target=' + target + ')')
        packaging_date_of_fixes.each do |packaging_date_of_fix|
          Log.log_debug(' packaging_date_of_fix=' +
                            packaging_date_of_fix.to_s)
        end
        packaging_date_of_fixes
      end

      # #######################################################################
      # name : step_build_nim_resource
      # param : input:step:string current step being done, to log it
      # param : input:target:string one particular target
      #   on which action is being done
      # param : input:hfixes_dates:hash with fix as key and packaging_date
      #   as value
      # return : NIM lpp resource built as key and array of sorted fixes
      #   by pkgdate as value
      # description : Builds NIM resource and returns its name
      # #######################################################################
      def step_build_nim_resource(step,
                                  target,
                                  hfixes_dates)
        Log.log_info('Flrtvc step : ' + step.to_s + ' (target=' + target + ')' +
                         ' hfixes_dates=' +
                         hfixes_dates.to_s)
        #
        returned = {}
        #
        target_nimresource_dir_name = get_flrtvc_name(:NIM_dir, target)
        Log.log_debug('Target_nimresource_dir_name=' +
                          target_nimresource_dir_name)
        #
        # first sort the hash by their value which is packaging_date
        #  then get only the keys
        packaging_dates_sorted = hfixes_dates.keys.sort
        # reverse
        packaging_dates_sorted.reverse!
        #
        fixes = []
        packaging_dates_sorted.each do |packaging_date|
          fixes << hfixes_dates[packaging_date]
        end
        #
        Log.log_debug('Fixes sorted by packaging date=' +
                          fixes.to_s)

        # Now fixes are sorted by packaging date
        fixes.each do |fix|
          fix_filename = ::File.join(get_flrtvc_name(:common_efixes), fix)
          Log.log_debug('Copying ' +
                            fix_filename +
                            ' into ' +
                            target_nimresource_dir_name)
          begin
            FileUtils.cp(fix_filename, target_nimresource_dir_name)
          rescue Errno::ENOSPC => e
            Log.log_err('Exception e=' + e.to_s)
            Flrtvc.increase_filesystem(target_nimresource_dir_name)
            FileUtils.cp(fix_filename, target_nimresource_dir_name)
          end
          Log.log_debug('Copied ' + fix_filename +
                            ' into ' + target_nimresource_dir_name)
        end
        #
        # return hash with lpp_source as key and sorted efix as value
        nim_lpp_source_resource = get_flrtvc_name(:NIM_res, target)
        Log.log_debug('Testing if NIM resource ' +
                          nim_lpp_source_resource + ' exists.')
        exists = Nim.lpp_source_exists?(nim_lpp_source_resource)
        if exists
          Log.log_debug('Already built NIM resource ' +
                            nim_lpp_source_resource)
          Nim.remove_lpp_source(nim_lpp_source_resource)
          Log.log_debug('Removing already built NIM resource ' +
                            nim_lpp_source_resource)
        end
        Log.log_info('Building NIM resource ' +
                         nim_lpp_source_resource)
        Nim.define_lpp_source(nim_lpp_source_resource,
                              target_nimresource_dir_name)
        Log.log_info('End building NIM resource ' +
                         nim_lpp_source_resource)
        #
        # remove fixe(s) if inter lock fileset detected
        fl_lock_fixes = {}
        fl_lock_fixes = filter_lock_fixes(target_nimresource_dir_name, fixes, target)
        returned[nim_lpp_source_resource] = fl_lock_fixes.keys
        Log.log_debug('In step_build_nim_resource returned=' +
                          returned.to_s)
        returned
      end

      # #######################################################################
      # name : step_install_fixes
      # param : input:step:string current step being done, to log it
      # param : input:target:string one particular target
      #   on which action is being done
      # param : input:nimres_sortedfixes:hash with nim resource as key
      #   and array of sorted fixes by pkgdate as value
      # return : nothing
      # description : performs efix installations for target
      # #######################################################################
      def step_install_fixes(step,
                             target,
                             nimres_sortedfixes)
        Log.log_info('Flrtvc step : ' + step.to_s + ' (target=' + target + ')' +
                         '  nimres_sortedfixes=' +
                         nimres_sortedfixes.to_s)
        #
        begin
          # efixes are sorted : most recent first
          nim_resource = nimres_sortedfixes.keys[0]
          efixes = nimres_sortedfixes.values[0]
          efixes_string = Utils.string_separated(efixes, ' ')
          #
          # efixes are applied
          Log.log_debug('Performing efix installation')
          Nim.perform_efix(target, nim_resource, efixes_string)
          Log.log_debug('End performing efix installation')
        rescue StandardError => e
          Log.log_err('Exception e=' + e.to_s)
        end
      end

      # #######################################################################
      # name : remove_nim_resources
      # return : nothing
      # description : For each target, remove specific NIM
      #   resource built for this target
      # This is a convenient method used for tests, when we need to do
      #  some cycles of install efixes/uninstall efixes.
      # #######################################################################
      def remove_nim_resources
        Log.log_info('In remove_nim_resources')
        @targets.each do |target|
          Log.log_debug('target=' + target)
          nim_lpp_source_resource = get_flrtvc_name(:NIM_res, target)
          exists = Nim.lpp_source_exists?(nim_lpp_source_resource)
          Log.log_debug('exists=' +
                            exists.to_s)
          if exists
            Nim.remove_lpp_source(nim_lpp_source_resource)
            Log.log_debug('Removing NIM resource ' +
                              nim_lpp_source_resource)
          else
            Log.log_debug('Already removed NIM resource ' +
                              nim_lpp_source_resource)
          end
        end
      end

      # #######################################################################
      # name : step_remove_fixes
      # param : input:step:string current step being done, to log it
      # param : input:target:string one particular target
      #   on which action is being done
      # return : nothing
      # description : For each target, uninstall efix.
      # This is a convenient method used for tests, when we need to do some
      #  cycles of install efixes/uninstall efixes.
      # #######################################################################
      def step_remove_fixes(step,
                            target)
        Log.log_info('Flrtvc step : ' + step.to_s + ' (target=' + target + ')')
        nim_lpp_source_resource = get_flrtvc_name(:NIM_res, target)
        begin
          Log.log_info('Removing efixes on ' + target)
          returned = Nim.perform_efix_uninstallation(target, nim_lpp_source_resource)
          if returned
            Log.log_info('End removing efixes on ' + target)
          else
            Log.log_err('Issue while removing efixes on ' + target)
          end
        rescue StandardError => e
          Log.log_err('Exception e=' + e.to_s)
        end
      end

      # #######################################################################
      # name : remove_downloaded
      # return : nothing
      # description : removes all efix downloaded files (*.tar *.epkg.Z)
      # This is a convenient method used for tests, when we need to do some
      #  cycles of install efixes/uninstall efixes.
      # #######################################################################
      def remove_downloaded_files
        Log.log_info('In remove_downloaded_files')
        begin
          Log.log_debug('Removing downloaded files')
          #  TBI
          Log.log_debug('End removing downloaded files')
        rescue StandardError => e
          Log.log_err('Exception e=' + e.to_s)
        end
      end

      # ########################################################################
      # name : download_fct
      # param : input:target:string one particular target
      #   on which action is being done
      # param : input:url_to_download:string
      # param : input:count:string
      # param : input:total:string
      # return : hash with efix file names as keys and either -1;0;1 as values
      #     -1 meaning that there was an error and download was not done
      #      0 meaning that download was not done, but this is normal as
      #        it was already done
      #      1 meaning that download was correctly done
      #   If URL indicates a single epkg file, hash contains only one file
      #   If URL indicates a tar file, hash may contain more than one file
      #   If URL indicates a directory, hash may contain more than one file
      # description : URL may follow different formats,
      #  and this function adapts itself to these formats.
      #  Download is done if necessary only, if the file was already downloaded
      #  then it is not done again.
      # ########################################################################
      def download_fct(target,
                       url_to_download,
                       count,
                       total)
        Log.log_debug('Into download_fct (target=' + target +
                          ') url_to_download=' + url_to_download +
                          ' count=' + count.to_s +
                          ' total=' + total.to_s)

        downloaded_filenames = {}
        unless %r{^(?<protocol>.*?)://(?<srv>.*?)/(?<dir>.*)/(?<name>.*)$} =~ url_to_download
          raise URLNotMatch "link: #{url_to_download}"
        end
        #
        common_efixes_dirname = get_flrtvc_name(:common_efixes)
        temp_dir = get_flrtvc_name(:temp_dir)
        tar_dir = get_flrtvc_name(:tar_dir)
        #
        if name.empty?
          #############################################
          # URL ends with /, look into that directory #
          #############################################
          case protocol
          when 'http', 'https'
            begin
              uri = URI(url_to_download)
              http = Net::HTTP.new(uri.host, uri.port)
              http.read_timeout = 10
              http.open_timeout = 10
              http.use_ssl = true if protocol.eql?('https')
              http.verify_mode = OpenSSL::SSL::VERIFY_NONE if protocol.eql?('https')
              request = Net::HTTP::Get.new(uri.request_uri)
              response = http.request(request)
              subcount = 0
              if response.is_a?(Net::HTTPResponse)
                b_download = 0
                response.body.each_line do |response_line|
                  next unless response_line =~ %r{<a href="(.*?.epkg.Z)">(.*?.epkg.Z)</a>}
                  url_of_file_to_download = ::File.join(url_to_download, Regexp.last_match(1))
                  local_path_of_file_to_download = \
                    ::File.join(common_efixes_dirname, Regexp.last_match(1))
                  Log.log_debug('Consider downloading ' +
                                    url_of_file_to_download +
                                    ' into ' +
                                    common_efixes_dirname +
                                    ':' + count.to_s + '/' + total.to_s + ' fixes.')
                  if !::File.exist?(local_path_of_file_to_download)
                    # Download file
                    Log.log_info('Downloading ' + url_of_file_to_download.to_s +
                                     ' into ' + common_efixes_dirname.to_s +
                                     ' and keeping into ' + local_path_of_file_to_download.to_s +
                                     ':' + count.to_s + '/' + total.to_s + ' fixes.')
                    b_download = download(target,
                                          url_of_file_to_download,
                                          local_path_of_file_to_download,
                                          protocol)
                  else
                    Log.log_debug('Not downloading ' + url_of_file_to_download.to_s +
                                      ' : already into ' + local_path_of_file_to_download.to_s +
                                      ':' + count.to_s + '/' + total.to_s + ' fixes.')
                    b_download = 0
                  end
                  downloaded_filenames[::File.basename(local_path_of_file_to_download)] = b_download
                  subcount += 1
                end
                Log.log_debug('Into download_fct (target=' +
                                  target +
                                  ') http/https url_to_download=' +
                                  url_to_download +
                                  ', subcount=' +
                                  subcount.to_s)
              end
            rescue Timeout::Error => error
              Log.log_err("Timeout sending event to server: #{error}")
              raise 'timeout error'
            end
          when 'ftp'
            #
            ftp_download_result = ftp_download(target,
                                               url_to_download,
                                               count,
                                               total,
                                               srv,
                                               dir,
                                               common_efixes_dirname)
            Log.log_debug('After download_fct name.empty ftp')
            downloaded_filenames.merge(ftp_download_result)
          else
            raise "protocol must be either 'http', 'https', ftp'"
          end
        elsif name.end_with?('.tar')
          #####################
          # URL is a tar file #
          #####################
          local_path_of_file_to_download = ::File.join(tar_dir, name)
          Log.log_debug('Consider downloading ' +
                            url_to_download +
                            ' into ' +
                            tar_dir +
                            " : #{count}/#{total} fixes.")
          if !::File.exist?(local_path_of_file_to_download)
            # download file
            Log.log_info("Downloading #{url_to_download} \
into #{tar_dir}: #{count}/#{total} fixes.")
            b_download = download(target,
                                  url_to_download,
                                  local_path_of_file_to_download,
                                  protocol)
            #
            if b_download == 1
              # We untar only if the tar file does not yet exist.
              # We consider that if tar file already exists,
              #  then it has been already untarred.
              Log.log_debug("Untarring #{local_path_of_file_to_download} \
into #{temp_dir} : #{count}/#{total} fixes.")
              untarred_files = untar(local_path_of_file_to_download, temp_dir)
              # Log.log_debug("untarred_files = " + untarred_files.to_s)
              #
              subcount = 1
              Log.log_debug('Copying ' + untarred_files.to_s + \
' into ' + common_efixes_dirname)
              untarred_files.each do |filename|
                # Log.log_debug("  copying filename " + filename
                #   +": #{count}.#{subcount}/#{total} fixes.")
                FileUtils.cp(filename, common_efixes_dirname)
                downloaded_filenames[::File.basename(filename)] = b_download
                subcount += 1
              end
            elsif b_download == 0
              Log.log_debug("Not downloading #{url_to_download} : already \
into #{tar_dir}: #{count}/#{total} fixes.")
              tarfiles = tar_tf(local_path_of_file_to_download)
              tarfiles.each { |x| downloaded_filenames[::File.basename(x)] = 0 }
            else
              Log.log_err("Error while downloading #{url_to_download} \
into #{tar_dir}: #{count}/#{total} fixes.")
              downloaded_filenames[url_to_download] = -1
            end
          else
            Log.log_debug("Already downloaded : not downloading #{url_to_download} \
into #{tar_dir}: #{count}/#{total} fixes.")
            tarfiles = tar_tf(local_path_of_file_to_download)
            tarfiles.each { |x| downloaded_filenames[::File.basename(x)] = 0 }
          end
        elsif name.end_with?('.epkg.Z')
          #######################
          # URL is an efix file #
          #######################
          local_path_of_file_to_download =
              ::File.join(common_efixes_dirname, ::File.basename(name))
          Log.log_debug('Consider downloading ' +
                            url_to_download +
                            ' into ' +
                            local_path_of_file_to_download +
                            " : #{count}/#{total} fixes.")
          if !::File.exist?(local_path_of_file_to_download)
            # download file
            Log.log_info("Downloading #{url_to_download} \
into #{local_path_of_file_to_download} : #{count}/#{total} fixes.")
            b_download = download(target,
                                  url_to_download,
                                  local_path_of_file_to_download,
                                  protocol)
          else
            Log.log_debug("Not downloading #{url_to_download} : already into \
                          #{local_path_of_file_to_download} \
: #{count}/#{total} fixes.")
            b_download = 0
          end
          downloaded_filenames[::File.basename(local_path_of_file_to_download)] = b_download
        end
        #
        Log.log_info('Into download_fct returning ' +
                         downloaded_filenames.to_s)
        downloaded_filenames
      end

      # ########################################################################
      # name : download
      # param : input:target:string
      # param : input:download_url:string
      # param : input:destination_file:string
      # param : input:protocol:string
      # return : either -1;0;1
      #  -1 meaning there was an error and download could not be done
      #   0 meaning download was not done, but it was normal, as already done
      #   1 meaning download has been correctly done
      # description : performs the download if the file is
      #  not yet downloaded.
      #  A retry mechanism which increases the file system size in
      #   case of ENOSPC
      # ########################################################################
      def download(target,
                   download_url,
                   destination_file,
                   protocol)
        Log.log_debug('Into download (target=' + target +
                          ') download_url=' + download_url +
                          ' destination_file=' + destination_file +
                          ' protocol=' + protocol)
        #
        returned = 0
        begin
          unless ::File.exist?(destination_file)
            ::File.open(destination_file, 'w') do |f|
              download_expected = open(download_url)
              bytes_copied = ::IO.copy_stream(download_expected, f)
              if protocol != 'ftp'
                bytes_expected = download_expected.meta['content-length']
                if bytes_expected.to_i != bytes_copied
                  Log.log_err("Expected #{bytes_expected} bytes but got #{bytes_copied}")
                  returned = -1
                end
              end
              returned = 1
            end
          end
        rescue Errno::ENOSPC => e
          ::File.delete(destination_file)
          Log.log_err('Automatically increasing file system as Exception e=' + e.to_s)
          Flrtvc.increase_filesystem(destination_file)
          return download(target, download_url, destination_file, protocol)
        rescue Errno::ETIMEDOUT => e
          ::File.delete(destination_file)
          Log.log_warning('Timeout while downloading: ' + download_url)
          Log.log_err('Exception e=' + e.to_s + ' : file ' + download_url + ' not downloaded')
          returned = -1
            # TODO: implement timeout on ftp download here, and a retry mechanism
        rescue StandardError => e
          ::File.delete(destination_file)
          Log.log_err('Exception e=' + e.to_s)
          returned = -1
        end
        Log.log_debug('download(...) returning ' + returned.to_s)
        returned
      end

      # ########################################################################
      # name : download
      # param : input:target:string
      # param : input:url_to_download:string
      # param : input:count:string
      # param : input:total:string
      # param : input:ftp_server:string
      # param : input:ftp_dir:string
      # param : input:destination_dir:string
      # return : hash with
      #   true if download has been done,
      #   false if download has been skipped,
      #  and filenames as values
      # description : performs the download if the file is
      #   not yet downloaded
      #  A retry mechanism which increases the file system size
      #   in case of ENOSPC
      # ########################################################################
      def ftp_download(target,
                       url_to_download,
                       count,
                       total,
                       ftp_server,
                       ftp_dir,
                       destination_dir)
        Log.log_debug('  Into download (target=' + target +
                          ') url_to_download=' + url_to_download +
                          ' count=' + count.to_s +
                          ' total=' + total.to_s +
                          ' ftp_server=' + ftp_server +
                          ' ftp_dir=' + ftp_dir +
                          ' destination_dir=' + destination_dir)
        returned_downloaded_filenames = {}
        #
        Net::FTP.open(ftp_server) do |ftp|
          ftp.login
          ftp.read_timeout = 300
          ftp.chdir(ftp_dir)
          files_on_ftp_server = ftp.nlst('*.epkg.Z')
          subcount = 0
          #
          files_on_ftp_server.each do |file_on_ftp_server|
            fix_to_download = ::File.join(url_to_download,
                                          ::File.basename(file_on_ftp_server))
            #
            begin
              # download file
              local_path_of_file_to_download =
                  ::File.join(destination_dir,
                              ::File.basename(file_on_ftp_server))
              Log.log_debug(' Consider downloading ' +
                                fix_to_download +
                                ' into ' +
                                local_path_of_file_to_download +
                                " : #{count}.#{subcount}/#{total} fixes.")
              #
              if !::File.exist?(local_path_of_file_to_download)
                Log.log_debug('  downloading ' + fix_to_download +
                                  'into ' +
                                  local_path_of_file_to_download +
                                  " : #{count}.#{subcount}/#{total} fixes.")
                #
                ftp.getbinaryfile(::File.basename(file_on_ftp_server),
                                  local_path_of_file_to_download)
                b_download = 1
              else
                Log.log_debug('  not downloading ' +
                                  fix_to_download +
                                  'into ' +
                                  local_path_of_file_to_download +
                                  " : #{count}.#{subcount}/#{total} fixes.")
                b_download = 0
              end
              #
              subcount += 1
              #
              returned_downloaded_filenames[::File.basename(local_path_of_file_to_download)] = b_download
            rescue Errno::ENOSPC => e
              Log.log_err('Automatically increasing file system when ftp_downloading as\
 Exception e=' + e.to_s)
              Flrtvc.increase_filesystem(destination_dir)
              return ftp_download(target,
                                  url_to_download,
                                  count,
                                  total,
                                  ftp_server,
                                  ftp_dir,
                                  destination_dir)
            rescue StandardError => e
              Log.log_err('Exception e=' + e.to_s)
              # Log.log_warning("Propagating exception of type '#{e.class}' when ftp_downloading!")
              returned_downloaded_filenames[::File.basename(local_path_of_file_to_download)] = -1
            end
          end
        end
        Log.log_debug('returned_downloaded_filenames=' + returned_downloaded_filenames.to_s)
        returned_downloaded_filenames
      end

      # ########################################################################
      # name : tar_tf
      # param : input:src:string
      # return : array of relative file names which belong to the tar file
      # description :
      # ########################################################################
      def tar_tf(file_to_untar)
        Log.log_debug('Into tar_tf file_to_untar=' + file_to_untar)
        returned = []
        begin
          command_output = []
          command = "/bin/tar -tf #{file_to_untar} | /bin/grep epkg.Z$"
          Utils.execute2(command, command_output)
          untarred_files_array = command_output[0].split("\n")
          # untarred_files = Utils.string_separated(untarred_files_array, ' ')
          untarred_files_array.each do |untarred_file|
            untarred_file = ::File.basename(untarred_file)
            returned << untarred_file
          end
        rescue StandardError => e
          Log.log_err('Exception e=' + e.to_s)
          Log.log_warning("Propagating exception of type \
'#{e.class}' when untarring!")
          raise e
        end
        Log.log_debug('Into tar_tf returned=' + returned.to_s)
        returned
      end

      # ########################################################################
      # name : untar
      # param : input:file_to_untar:string
      # param : input:directory_for_untar:string
      # return : array of absolute file names which have been untarred.
      # description : performs untar and returns result of untar
      # ########################################################################
      def untar(file_to_untar,
                directory_for_untar)
        Log.log_debug('Into untar file_to_untar=' + file_to_untar +
                          ' directory_for_untar=' + directory_for_untar)
        returned = []
        begin
          command_output = []
          command = "/bin/tar -tf #{file_to_untar} | /bin/grep epkg.Z$"
          Utils.execute2(command, command_output)
          untarred_files_array = command_output[0].split("\n")
          untarred_files = Utils.string_separated(untarred_files_array,
                                                  ' ')
          #
          cmd = "/bin/tar -xf #{file_to_untar} \
-C #{directory_for_untar} #{untarred_files}"
          Utils.execute(cmd)
          #
          untarred_files_array.each do |untarred_file|
            absolute_untarred_file =
                ::File.join(directory_for_untar,
                            untarred_file)
            returned << absolute_untarred_file
          end
        rescue StandardError => e
          Log.log_err('Exception e=' + e.to_s)
          if e.message =~ /No space left on device/
            Flrtvc.increase_filesystem(directory_for_untar)
            returned = untar(file_to_untar, directory_for_untar)
          else
            Log.log_warning("Propagating exception of type '#{e.class}' \
when untarring!")
            raise e
          end
        rescue StandardError => e
          Log.log_err('Exception e=' + e.to_s)
          Log.log_warning("Propagating exception of type '#{e.class}' \
when untarring!")
          raise e
        end
        Log.log_debug('Into untar returned=' + returned.to_s)
        returned
      end

      # #######################################################################
      # name : min_max_level_prereq_of
      # param : input:fixfile:string
      #
      # return : hash with lpp as keys and [min, max] as values, for all lpp
      #   impacted by the efix
      # description : this method parses the fix to get
      #   the prereq min max values
      # #######################################################################
      def min_max_level_prereq_of(fixfile)
        Log.log_debug('Into is_min_max_level_prereq_of fixfile=' + fixfile)
        returned = {}
        # By default we return true, meaning the fix can be applied
        begin
          # Get 'min level' and 'max level' from the fix
          command_output = []
          # environment: {'LANG' => 'C'}
          Utils.execute2("/usr/sbin/emgr -dXv3 -e #{fixfile} | /bin/grep -p \\\"PREREQ",
                         command_output)
          #
          if !command_output[0].nil? && !command_output[0].empty?
            command_output[0].lines[3..-2].each do |command_output_line|
              # Log.log_debug("command_output_line=" + command_output_line.to_s)
              next if command_output_line.start_with?('#') # skip comments
              next unless command_output_line =~ /^(.*?)\s+(\d+\.\d+\.\d+\.\d+)\s+(\d+\.\d+\.\d+\.\d+)(.*?)$/

              lpp = Regexp.last_match(1)
              min_a = Regexp.last_match(2).split('.')
              splevel_min = SpLevel.new(min_a[0], min_a[1], min_a[2], min_a[3])
              max_a = Regexp.last_match(3).split('.')
              splevel_max = SpLevel.new(max_a[0], max_a[1], max_a[2], max_a[3])
              Log.log_debug('fixfile=' + fixfile +
                                ' lpp=' + lpp.to_s +
                                ' splevel_min=' + splevel_min.to_s +
                                ' splevel_max=' + splevel_max.to_s)
              returned[lpp] = [splevel_min, splevel_max]
            end
          else
            Log.log_debug('No prereq set on this fix')
          end
          returned
        rescue StandardError => e
          Log.log_warning("Propagating exception of type '#{e.class}' when checking!")
          raise e
        end
      end

      # #######################################################################
      # name : packaging_date_of
      # param : input:fixfile:string
      #
      # return : packaging_date formatted in such a way it can be sorted
      # description : this method parses the fix to get packaging date and
      #   format this date so that if can be sorted
      # #######################################################################
      def packaging_date_of(fixfile)
        Log.log_debug('Into packaging_date_of fixfile=' + fixfile)
        packaging_date = ''
        begin
          # Get 'PACKAGING DATE' from the fix
          command_output = []
          # environment: {'LANG' => 'C'}
          Utils.execute2("/usr/sbin/emgr -dXv3 -e #{fixfile} | /bin/grep -w 'PACKAGING DATE:'",
                         command_output)
          # We get something like that : PACKAGING DATE:   Fri Apr  1 04:14:10 CDT 2016
          # We match it                                         0   1  2  3  4      5
          if !command_output[0].nil? && !command_output[0].empty?
            to_regex = command_output[0].chomp
            Log.log_debug('to_regex=|' + to_regex + '|')
            to_regex =~ /PACKAGING DATE:\s+\w+\s+(\w+)\s+(\d+)\s+(\d+):(\d+):(\d+)\s+\w+\s+(\d+)\s*/
            #                                             0       1       2     3    4              5
            hash_months = {'Jan' => '01', 'Feb' => '02', 'Mar' => '03',
                           'Apr' => '04', 'May' => '05', 'Jun' => '06',
                           'Jul' => '07', 'Aug' => '08', 'Sep' => '09',
                           'Oct' => '10', 'Nov' => '11', 'Dec' => '12'}
            #
            month = Regexp.last_match(1)
            s_month = hash_months[month.to_s]
            #
            day = Regexp.last_match(2)
            # Log.log_debug('day=' + day.to_s)
            s_day = if day.to_i <= 9
                      '0' + day.to_s
                    else
                      day.to_s
                    end
            #
            hour = Regexp.last_match(3)
            minute = Regexp.last_match(4)
            second = Regexp.last_match(5)
            #
            year = Regexp.last_match(6)
            #
            packaging_date = year + '_' + s_month + '_' + s_day + '_' + \
hour.to_s + '_' + minute.to_s + '_' + second.to_s
            Log.log_debug('  Packaging_date=' + packaging_date)
          else
            Log.log_debug('  No PACKAGING DATE set on this fix')
          end
        rescue StandardError => e
          Log.log_warning("Propagating exception of type \
'#{e.class}' when checking!")
          raise e
        end
        packaging_date
      end

      # #######################################################################
      # name : level_prereq_ok?
      # param : input:target:string
      # param : input:lpp:string
      # param : input:min:string
      # param : input:max:string
      #
      # return :
      # description : this method checks that the level of the fix
      #   can be applied on the system.
      #  To perform this check, the 'min level' of the fix and the
      #   'max level' of the fix are compared with the current level
      #   of the fileset.
      #  If the current level of the fileset is between 'min level'
      #   and 'max level', then it is ok and it returns 'true',
      #   otherwise it is not ok and it returns 'false'.
      #
      #  If this method returns true, it means that the
      #    fix can be applied on the current target,
      #    as it satisfies all PREREQ.
      #  If this method returns false, it means that the fix
      #    cannot be applied on the current target, as at least
      #    one PREREQ is not satisfied.
      #
      # #######################################################################
      def level_prereq_ok?(target,
                           lpp,
                           min,
                           max)
        Log.log_debug('Into level_prereq_ok? (target=' +
                          target +
                          '), lpp=' +
                          lpp +
                          ', min=' +
                          min.to_s +
                          ', max=' +
                          max.to_s)
        # By default we return true, meaning the fix can be applied
        returned = true
        #
        begin
          lslpp_file = get_flrtvc_name(:lslpp, target)
          command_output = []
          # environment: {'LANG' => 'C'}
          command = '/bin/cat ' + lslpp_file + ' | /bin/grep ":' + lpp + ':" | /bin/cut -d: -f3'
          Utils.execute2(command,
                         command_output)
          # Sometimes added to . we can find - as separator
          lvl_a = command_output[0].split(/[.-]/)
          # Fill with 0 any missing field
          (lvl_a.length..3).each { |i|
            lvl_a[i] = 0
          }
          lvl = SpLevel.new(lvl_a[0], lvl_a[1], lvl_a[2], lvl_a[3])
          #
          Log.log_debug('Into level_prereq_ok? (target=' +
                            target +
                            ') lvl=' +
                            lvl.to_s +
                            ', lpp=' +
                            lpp +
                            ' min=' +
                            min.to_s +
                            ' max=' +
                            max.to_s)
          returned = false unless min <= lvl && lvl <= max
          returned
        rescue StandardError => e
          Log.log_warning("Propagating exception of type '#{e.class}' \
when checking!")
          raise e
        end
      end

      # ########################################################################
      # name : filter_lock_fixes
      # param : input:lpp_source_dir:string
      # param : input:efixes_basenames:array
      # param : input:target:string
      #
      # return hach table efix=>package_names filtered by locked filesets
      # description : filtering  fixes list by locked filesets
      # ########################################################################
      def filter_lock_fixes (lpp_source_dir, efixes_basenames, target)
        locked_pkg = []
        list_pkg_name = {}
        # get locked package from client
        begin
          locked_pkg = get_locked_packages(target)
        rescue EmgrCmdError => e
            Log.log_debug("filter_lock_fixes -> get_locked_packages Error for client #{target}:#{e}")
        end
        Log.log_debug("Locked package list for client [#{target}]: #{locked_pkg}")
        # get package name from efix list
        list_pkg_name = get_efix_packaging_names(lpp_source_dir, efixes_basenames)
        list_pkg_name_copy = list_pkg_name.dup
        Log.log_debug("Package list name: #{list_pkg_name}")
        # remove efix from list if package is locked
        locked_pkg.each do |item|
          list_pkg_name.delete_if { |_, v| v.include?(item) }
        end
        # remove efix with package name doublon
        unlock_efixes_basenames = {}
        list_pkg_name.each do |k, v|
          unlock_efixes_basenames[k] = v
          del_key = []
          list_pkg_name.delete(k)
          v.each do |item|
            list_pkg_name.each do |ky, va|
              del_key << ky if va.include?(item)
            end
            list_pkg_name.delete_if { |kk, _| del_key.include?(kk) }
          end
        end
        # next if efix list to apply is empty
        if unlock_efixes_basenames.keys.empty?
          Log.log_info("[#{target}] Have vulnerabilities but no installion will be done due to locked packages")
          Log.log_info("[#{target}] Use force option to remove locked packages before update")
        end
        # check if conflict detected to log message
        unlock_efixes_basenames.each do |key, _|
          list_pkg_name_copy.delete(key)
        end
        unless list_pkg_name_copy.empty?
          Log.log_info("[#{target}] Some Efix(es) will not be installed due to a conflict on packages:")
          unless locked_pkg.empty?
            Log.log_info("\t[#{target}]Locked packages:")
            Log.log_info("\t" + locked_pkg.join("\n\t"))
            Log.log_info("\n\tUse force option to remove locked packages before update")
          end
          Log.log_info("\t\tEFix\t=>    Packages   ")
          Log.log_info("\t\t------------------------")
          list_pkg_name_copy.each do |k, v|
            Log.log_info("\t\t#{format('%s', k)}")
            v.each do |item|
              Log.log_info("\t\t\t\t=>#{format('%s', item)}")
            end
          end
        end
        unlock_efixes_basenames
      end

      # ########################################################################
      # name : get_locked_packages
      # param : input:machine:string
      #
      # return array of locked packages for a specific client
      # description : get package names impacted from specific fileset
      #    raise EmgrCmdError in case of error
      # ########################################################################
      def get_locked_packages(machine)
        locked_packages = []
        emgr_s = "/usr/lpp/bos.sysmgt/nim/methods/c_rsh #{machine} \"/usr/sbin/emgr -P\""
        Log.log_debug("EMGR listing package locks: #{emgr_s}")
        exit_status = Open3.popen3({ 'LANG' => 'C' }, emgr_s) do |_stdin, stdout, stderr, wait_thr|
          stdout.each_line do |line|
            next if line =~ /^PACKAGE\s*INSTALLER\s*LABEL/
            next if line =~ /^=*\s\=*\s\=*/
            line_array = line.split(' ')
            Log.log_debug("emgr: adding locked package #{line_array[0]} to locked package list")
            locked_packages.push(line_array[0])
            Log.log_debug("[STDOUT] #{line.chomp}")
          end
          stderr.each_line do |line|
            Log.log_debug("[STDERR] #{line.chomp}")
          end
          wait_thr.value # Process::Status object returned.
        end
        raise EmgrCmdError, "Error: Command \"#{emgr_s}\" returns above error!" unless exit_status.success?
        locked_packages.delete_if { |item| item.nil? || item.empty? }
        locked_packages
      end

      # ########################################################################
      # name : get_pkg_names
      # param : input:lpp_source_dir:string
      # param : input:fileset:string
      #
      # return array of packaging names
      # description : get package names impacted from specific fileset
      #    raise EmgrCmdError in case of error
      # ########################################################################
      def get_pkg_names(lpp_source_dir, fileset)
        pkg_names = []
        cmd_s = "/usr/sbin/emgr -d -e #{lpp_source_dir}/#{fileset} -v3 | /bin/grep -w 'PACKAGE:' | /bin/cut -c16-"
        Log.log_debug("get_pkg_name: #{cmd_s}")
        Open3.popen3({ 'LANG' => 'C' }, cmd_s) do |_stdin, stdout, stderr, wait_thr|
          stderr.each_line do |line|
            Log.log_debug("[STDERR] #{line.chomp}")
          end
          unless wait_thr.value.success?
            stdout.each_line { |line| Log.log_debug("[STDOUT] #{line.chomp}") }
            raise EmgrCmdError, "Error: Command \"#{cmd_s}\" returns above error!"
          end
           stdout.each_line do |line|
            Log.log_debug("[STDOUT] #{line.chomp}")
            # match "  devices.pciex.df1060e214103404.com"
            next unless line =~ /^\s*(\S*[.]\S*)\s*$/
            pkg_names << Regexp.last_match(1)
          end
        end
        Log.log_debug("get_pkg_names for: #{lpp_source_dir}/#{fileset} => #{pkg_names}")
        pkg_names
      end

      # ########################################################################
      # name : get_efix_packaging_names
      # param : input:lpp_source_dir:string
      # param : input:filesets:array
      #
      # return hash table package names (key = fileset)
      # description : get package names from fileset list
      # ########################################################################
      def get_efix_packaging_names(lpp_source_dir, filesets)
        pkg_names_h = {}
        filesets.each do |fileset|
          begin
            pkg_names_h[fileset] = get_pkg_names(lpp_source_dir, fileset)
          rescue EmgrCmdError => e
            Log.log_debug("get_efix_packaging_names -> get_pkg_name Error: #{e}")
          end
        end
        pkg_names_h
      end

      # ########################################################################
      # name : increase_filesystem
      # param : input:path:string
      #
      # return : nothing
      # description : this method increases file system
      #   hosting the given 'path' by 100 MB
      # ########################################################################
      def self.increase_filesystem(path)
        Log.log_debug('In increase_filesystem path=' + path)

        # First retrieve FS hosting the given path
        mounts = []
        command_output = []
        Utils.execute2('/usr/bin/df |/usr/bin/tail -n +2 ',
                       command_output)
        lines = command_output[0].split('\n')
        lines.each do |line|
          items = line.split(' ')
          Log.log_debug('items[6]=' + items[6])
          mounts << items[6]
        end
        # Get longest match
        mount = mounts.sort_by!(&:length).reverse!.detect { |mnt| path =~ /#{Regexp.quote(mnt.to_s)}/ }
        # Then increase by 100 MB
        command_output = []
        Utils.execute2("/usr/sbin/chfs -a size=+100M #{mount}",
                       command_output)
        Log.log_debug('command_output=' + command_output[0])
      end
    end # Flrtvc

    # ############################
    #     E X C E P T I O N      #
    # ############################
    class FlrtvcNotFound < StandardError
    end
    #
    class URLNotMatch < StandardError
    end
    #
    class InvalidAparProperty < StandardError
    end
    #
    class InvalidCsvProperty < StandardError
    end
    #
    class EmgrCmdError < StandardError
    end
    #
  end
end
