require 'pathname'
require 'open-uri'
require 'fileutils'
require 'net/http'
require 'net/https'
require 'net/ftp'
require 'csv'
require 'open3'
require_relative './Utils.rb'
require_relative './Nim.rb'
require_relative './Remote/c_rsh.rb'

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
      #  arsg[4]:clean:string ['yes', 'no'], default: no
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
            @root_dir = if root =~ /^\//
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
          clean = args[4]
          @step = step
          @level = level
          @clean = clean
        else
          @step = ''
          @level = ''
          @clean = 'yes'
        end

        #
        Log.log_info('Flrtvc constructor ' +
                         '@targets=' + @targets.to_s +
                         ' @root=' + @root.to_s +
                         ' @step=' + @step.to_s +
                         ' @level=' + @level.to_s +
                         ' @clean=' + @clean.to_s)

        #
        # to keep in memory the already parsed fixes
        # so that they are not parsed again and again
        #
        @lppminmax_of_fixes = {}

        #
        # to keep in memory the list of fixes per url
        #  so that we can build teh list of fix for each target,
        #  even if the url has already been downloaded
        #
        @listoffixes_per_url = {}
      end

      # ########################################################################
      # name : check_flrtvc
      # param :
      # return :
      # description :
      # ########################################################################
      def check_flrtvc
        raise FlrtvcNotFound unless ::File.exist?('/usr/bin/flrtvc.ksh')
        # raise FlrtvcNotFound unless File.zero?('/usr/bin/flrtvc.ksh')
        # File.zero returns false if file is not found or if file size is zero

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
      def get_flrtvc_name(type, target = '', name_suffix = '')
        returned = ''
        case type
          when :temp_dir
            returned = ::File.join(@root_dir,
                                   'temp')
            # check it exist
            Automation::Lib::Utils.check_directory(returned)
            # clean it
            FileUtils.rm_rf Dir.glob("#{returned}/*")
            returned
          when :tar_dir
            returned = ::File.join(@root_dir,
                                   'tar_dir')
            # check it exist
            Automation::Lib::Utils.check_directory(returned)
            returned
          when :tempftp_download
            returned = ::File.join(@root_dir,
                                   'tempftp_download')
            # check it exist
            Automation::Lib::Utils.check_directory(returned)
            returned
          when :common_efixes
            returned = ::File.join(@root_dir,
                                   'common_efixes')
            Automation::Lib::Utils.check_directory(returned)
            returned
          when :efixes
            returned = ::File.join(@root_dir,
                                   'efixes',
                                   "#{target}_#{name_suffix}")
            Automation::Lib::Utils.check_directory(returned)
            returned
          when :emgr
            returned = ::File.join(@root_dir,
                                   "#{target}_emgr.txt")
          when :filesets
            returned = ::File.join(@root_dir,
                                   "#{target}_filesets.txt")
          when :flrtvc
            returned = ::File.join(@root_dir,
                                   "#{target}_flrtvc.csv")
          when :lslpp
            returned = ::File.join(@root_dir,
                                   "#{target}_lslpp.txt")
          when :NIM_dir
            returned = ::File.join(@root_dir,
                                   "#{target}_NIM",
                                   'emgr',
                                   'ppc')
            Automation::Lib::Utils.check_directory(returned)
            returned
          when :NIM_res
            returned = "PAA_FLRTVC_#{target}"
          when :URL
            returned = ::File.join(@root_dir,
                                   "#{target}_URL.txt")
          when :YML
            if name_suffix == 'lppminmax_of_fixes'
              returned = ::File.join(@root_dir,
                                     'common_efixes',
                                     "#{target}_#{name_suffix}.yml")
            else
              returned = ::File.join(@root_dir,
                                     "#{target}_#{name_suffix}.yml")
            end
            returned
          else
            returned = ::File.join(@root_dir,
                                   type + "_#{target}.txt")
        end
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
      def mine_this_step(step, target)
        Log.log_info(' Into mine_this_step for target=' + target + \
' step=' + step.to_s + ' clean=' + @clean.to_s)
        returned = {}
        target_yml_file = get_flrtvc_name(:YML, target, step)
        Log.log_info('target_yml_file=' + target_yml_file)

        #
        if @clean == :yes
          begin
            Log.log_info(' Into mine_this_step  removing ' + target_yml_file)
            File.delete(target_yml_file)
          rescue StandardError
            # if file does not exist, dont care
          end
        else
          Log.log_info(' Into mine_this_step  keeping ' + target_yml_file)
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
      def run_step(step, target, param = '')
        Log.log_debug('Into run_step(' + step.to_s + ', ' +
                          target + ', ' + param.to_s + ')')
        case step
          when :status
            returned = step_status(step, target)
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
          else
            Log.log_err('Unknown step ' + step.to_s)
        end
        returned
      end

      # ########################################################################
      # name : step_status
      # param : input:step:string current step being done, to log it
      # param : input:target:string one particular target on
      #   which action is being done
      # return : status of the target
      # description : please note this step is as well done and
      #  integrated into the 'standalones' factor
      # ########################################################################
      def step_status(step, target)
        Log.log_debug('Into step ' + step.to_s + ' target=' + target)
        #status_output = {}
        status_output = Utils.status(target)
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
      def step_run_flrtvc(step, target)
        Log.log_debug('Into step_run_flrtvc target=' + target)

        mine_this_step_hash = mine_this_step(step, target)
        if mine_this_step_hash[false].nil?
          Log.log_info(' Doing mine_this_step for target=' + target +
                           ' step=' + step.to_s)
          #
          lslpp_file = get_flrtvc_name(:lslpp, target)
          Log.log_debug('lslpp_file=' + lslpp_file)
          #
          url_file = get_flrtvc_name(:URL, target)
          Log.log_debug('url_file=' + url_file)
          #
          emgr_file = get_flrtvc_name(:emgr, target)
          Log.log_debug('emgr_file=' + emgr_file)
          #
          flrtvc_file = get_flrtvc_name(:flrtvc, target)
          Log.log_debug('flrtvc_file=' + flrtvc_file)

          #
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
            returned = Automation::Lib::Remote.c_rsh(target, cmd1, lslpp_output)
            if returned.success?
              File.open(lslpp_file, 'w') {|file| file.write(lslpp_output)}
              Log.log_debug('lslpp_file ' + lslpp_file + ' written')
            end
            #
            cmd2 = '/usr/sbin/emgr -lv3'
            emgr_output = ''
            returned = Automation::Lib::Remote.c_rsh(target, cmd2, emgr_output)
            if returned.success?
              File.open(emgr_file, 'w') {|file| file.write(emgr_output)}
              Log.log_debug('emgr_file ' + emgr_file + ' written')
            end
          end

          if @level != :all
            cmd = "/usr/bin/flrtvc.ksh -l #{lslpp_file} -e #{emgr_file} \
-t #{@level}" # {apar_s} #{filesets_s} #{csv_s}
          else
            cmd = "/usr/bin/flrtvc.ksh -l #{lslpp_file} -e #{emgr_file}" \
# {apar_s} #{filesets_s} #{csv_s}
          end

          flrtvc_command_output = []
          Utils.execute2(cmd, flrtvc_command_output)

          # persist to yaml
          target_yml_file = get_flrtvc_name(:YML, target, step)
          File.write(target_yml_file, flrtvc_command_output[0].to_yaml)
          flrtvc_output = flrtvc_command_output[0]

        else
          Log.log_info(' NOT Doing mine_this_step for target=' + target +
                           ' step=' + step.to_s)
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
      def step_parse_flrtvc(step, target, flrtvc_report)
        Log.log_debug('Into step_parse_flrtvc target=' + target)

        mine_this_step_hash = mine_this_step(step, target)
        if mine_this_step_hash[false].nil?
          Log.log_info(' Doing mine_this_step for target=' + target +
                           ' step=' + step.to_s)

          array_of_fixes = CSV.parse(flrtvc_report, headers: true, col_sep: '|')

          # catch all download URLs which are in column with 'Download URL' header
          h_download_urls = {}
          download_urls = []
          advisories = []
          advisory_urls = []
          filesets = []
          array_of_fixes.each do |fix|
            fileset = fix['Fileset']
            filesets << fileset

            download_url = fix['Download URL']
            if !download_url.nil?
              if download_url.eql?('See advisory')
                advisory_url = fix['Bulletin URL']
                advisories << fix.to_s
                advisory_urls << advisory_url
              else
                Log.log_debug('download_url=' + download_url)
                if download_url =~ \
%r{^(http|https|ftp)://(aix.software.ibm.com|public.dhe.ibm.com)/(aix/ifixes/.*?/|aix/efixes/security/.*?.tar)$}
                  download_urls << download_url
                  h_download_urls[download_url] = fileset
                end
              end
            else
              Log.log_debug('download_url=nil')
            end
          end
          filesets.uniq!
          filesets.sort!

          Log.log_info('For ' + target + ", we found #{h_download_urls.size} \
different download links over #{array_of_fixes.size} vulnerabilities \
and #{filesets.size} filesets.")

          advisory_target_yml_file = get_flrtvc_name(:YML,
                                                     target,
                                                     :AdvisoryFlrtvc)
          File.write(advisory_target_yml_file, advisories.to_yaml)
          Log.log_info('See list of advisories mentionned by flrtvc into ' +
                           advisory_target_yml_file)

          advisory_urls_target_yml_file = get_flrtvc_name(:YML,
                                                          target,
                                                          :AdvisoryURLs)
          File.write(advisory_urls_target_yml_file, advisory_urls.to_yaml)
          Log.log_info('See list of advisory URLs mentionned by flrtvc into ' +
                           advisory_urls_target_yml_file)

          download_urls.uniq!
          download_urls.sort!
          download_urls.reverse!

          # persist to yaml
          target_yml_file = get_flrtvc_name(:YML, target, step)
          File.write(target_yml_file, download_urls.to_yaml)

        else
          Log.log_info(' NOT Doing mine_this_step for target=' + target +
                           ' step=' + step.to_s)
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
      #
      # return : listofkeptfixes_of_target
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
      def step_perform_downloads(step, target, urls_of_target)
        Log.log_debug('Into step_perform_downloads target=' + target +
                          ' urls_of_target=' + urls_of_target.to_s)

        mine_this_step_hash = mine_this_step(step, target)
        if mine_this_step_hash[false].nil?
          Log.log_info(' Doing mine_this_step for target=' + target +
                           ' step=' + step.to_s)
          Log.log_info(' Into step_perform_downloads target=' + target +
                           ' building now listoffixes for this target')
          total = urls_of_target.length
          index = 0
          efixes_and_downloadstatus = {}

          urls_of_target.each do |url|
            Log.log_debug('Into step_perform_downloads target=' + target +
                              ' download url=' + url)
            index += 1
            listoffixes_already_downloaded = @listoffixes_per_url[url]
            if listoffixes_already_downloaded.nil?
              Log.log_debug('Into step_perform_downloads target=' +
                                target +
                                ' download url=' +
                                url + ' not yet downloaded.')
              efixes_and_status_of_url = download_fct(target,
                                                      url,
                                                      index,
                                                      total)
              Log.log_debug('Into step_perform_downloads target=' +
                                target +
                                ' download url=' +
                                url +
                                ' efixes_and_status_of_url=' +
                                efixes_and_status_of_url.to_s)
              @listoffixes_per_url[url] = efixes_and_status_of_url.keys
              efixes_and_downloadstatus =
                  efixes_and_downloadstatus.merge(efixes_and_status_of_url)
            else
              Log.log_debug('Into step_perform_downloads target=' +
                                target +
                                ' download url=' +
                                url + ' already downloaded.')
              efixes_and_status_of_url = {}
              listoffixes_already_downloaded.each {|x| efixes_and_status_of_url[x] = false}
              Log.log_debug('Into step_perform_downloads target=' +
                                target +
                                ' download url=' +
                                url +
                                ' efixes_and_status_of_url=' +
                                efixes_and_status_of_url.to_s)
              efixes_and_downloadstatus =
                  efixes_and_downloadstatus.merge(efixes_and_status_of_url)
            end
          end

          counter = efixes_and_downloadstatus.values.count {|v| v}
          Log.log_debug('Into step_perform_downloads target=' + target +
                            ' efixes_and_downloadstatus=' + efixes_and_downloadstatus.to_s +
                            ' counter=' + counter.to_s)
          listoffixes = efixes_and_downloadstatus.keys
          listoffixes.sort!
          listoffixes.reverse!

          # persist to yaml
          target_yml_file = get_flrtvc_name(:YML, target, step)
          File.write(target_yml_file, listoffixes.to_yaml)
        else
          Log.log_info(' NOT Doing mine_this_step for target=' +
                           target +
                           ' step=' +
                           step.to_s)
          listoffixes = mine_this_step_hash[false]
        end

        Log.log_info(' Into step_perform_downloads target=' +
                         target +
                         ' listoffixes=' + listoffixes.to_s +
                         ' (' + listoffixes.length.to_s + ')')
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
      def step_check_fixes(step, target, listoffixes)
        Log.log_info(' Into step_check_fixes target=' + target +
                         ' listoffixes=' + listoffixes.to_s)

        mine_this_step_hash = mine_this_step(step, target)
        packaging_date_of_fixes = {}
        if mine_this_step_hash[false].nil?

          Log.log_info(' Into step_check_fixes target=' +
                           target +
                           ' checking now prerequisites for this listoffixes')
          # Check level prereq
          common_efixes_dirname = get_flrtvc_name(:common_efixes)
          listofkeptfixes = []

          ifix_ct_for_this_target = 0
          ifix_nb_for_this_target = listoffixes.length

          ###
          lppminmax_of_fixes_hash = mine_this_step('lppminmax_of_fixes',
                                                   'all')
          Log.log_info('Starting with lppminmax_of_fixes_hash=' + \
lppminmax_of_fixes_hash.to_s)
          @lppminmax_of_fixes = if lppminmax_of_fixes_hash[false].nil?
                                  {}
                                else
                                  lppminmax_of_fixes_hash[false]
                                end
          Log.log_info('Starting with @lppminmax_of_fixes=' + \
 @lppminmax_of_fixes.length.to_s)
          ###


          Log.log_debug('Into step_check_fixes target=' + target +
                            ' lppminmax_of_fixes=' + @lppminmax_of_fixes.to_s)
          listoffixes.each do |fix|
            Log.log_debug('Into step_check_fixes target=' + target + ' fix=' + fix)
            ifix_ct_for_this_target += 1
            existing_lppminmax_of_fixes = @lppminmax_of_fixes[fix]
            lpps_minmax_of_fix = {}
            if existing_lppminmax_of_fixes.nil? || existing_lppminmax_of_fixes.empty?
              # If not found, we parse the fix to get all lpp, min, max
              #   (one fix may contain several lpps)
              lpps_minmax_of_fix = min_max_level_prereq_of(::File.join(common_efixes_dirname,
                                                                       fix))
              if !lpps_minmax_of_fix.nil? && !lpps_minmax_of_fix.empty?
                Log.log_debug('new lpps_minmax_of_fixes=' + lpps_minmax_of_fix.to_s)
                Log.log_debug('before @lppminmax_of_fixes.length=' + @lppminmax_of_fixes.length.to_s)
                @lppminmax_of_fixes[fix] = lpps_minmax_of_fix
                Log.log_debug('after @lppminmax_of_fixes.length=' + @lppminmax_of_fixes.length.to_s)
              end
            else
              Log.log_debug('    old existing_lppminmax_of_fixes=' +
                                existing_lppminmax_of_fixes.to_s)
              # If found, we take the already found values
              lpps_minmax_of_fix = existing_lppminmax_of_fixes
            end

            # Then we check against the lpp level of this target
            kept_fix_for_this_target = true
            unless lpps_minmax_of_fix.empty?
              lpps_minmax_of_fix.keys.each do |lpp|
                (min, max) = lpps_minmax_of_fix[lpp]
                if is_level_prereq_ok?(target, lpp, min, max)
                else
                  Log.log_info(' Into step_check_fixes target=' + target +
                                   ' fix=' + fix +
                                   ' (' + ifix_ct_for_this_target.to_s + '/' +
                                   ifix_nb_for_this_target.to_s +
                                   ') cannot be applied.')
                  kept_fix_for_this_target = false
                  break
                end
              end
            end

            next unless kept_fix_for_this_target
            Log.log_info(' Into step_check_fixes target=' + target +
                             ' fix=' + fix +
                             ' (' + ifix_ct_for_this_target.to_s + '/' +
                             ifix_nb_for_this_target.to_s + ') can be applied.')
            listofkeptfixes << fix
          end

          Log.log_info(' Into step_check_fixes target=' + target +
                           ' listofkeptfixes=' + listofkeptfixes.to_s +
                           ' (' + listofkeptfixes.length.to_s + ')')

          # persist to yaml the matching between fixes/lpp/min&max
          lppminmax_of_fixes_yml_file = get_flrtvc_name(:YML,
                                                        'all',
                                                        'lppminmax_of_fixes')
          Log.log_debug('Persisting @lppminmax_of_fixes.length=' +
                            @lppminmax_of_fixes.length.to_s)
          File.write(lppminmax_of_fixes_yml_file, @lppminmax_of_fixes.to_yaml)

          # Sort the fixes by packaging date
          Log.log_debug('Into step_check_fixes target=' + target +
                            ' Sort the fixes by packaging date')
          listofkeptfixes.each do |fix|
            packaging_date = packaging_date_of(::File.join(common_efixes_dirname,
                                                           fix))
            packaging_date_of_fixes[packaging_date] = fix
          end

          # persist to yaml match between fix and packaging date
          target_yml_file = get_flrtvc_name(:YML, target, step)
          File.write(target_yml_file, packaging_date_of_fixes.to_yaml)

        else
          Log.log_info(' NOT Doing mine_this_step for target=' +
                           target +
                           ' step=' +
                           step.to_s)
          packaging_date_of_fixes = mine_this_step_hash[false]
        end

        Log.log_info(' Into step_check_fixes target=' +
                         target +
                         ' packaging_date_of_fixes=' +
                         packaging_date_of_fixes.to_s +
                         ' (' + packaging_date_of_fixes.length.to_s + ')')
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
      def step_build_nim_resource(_step, target, hfixes_dates)
        Log.log_debug('In step_build_nim_resource target=' +
                          target +
                          ' hfixes_dates=' +
                          hfixes_dates.to_s)

        returned = {}

        target_nimresource_dir_name = get_flrtvc_name(:NIM_dir, target)
        Log.log_debug('  target_nimresource_dir_name=' +
                          target_nimresource_dir_name)

        # first sort the hash by their value which is packaging_date
        #  then get only the keys
        packaging_dates_sorted = hfixes_dates.keys.sort
        # reverse
        packaging_dates_sorted.reverse!

        fixes = []
        packaging_dates_sorted.each do |packaging_date|
          fixes << hfixes_dates[packaging_date]
        end

        Log.log_debug('  fixes sorted by packaging date=' +
                          fixes.to_s)

        # Now fixes are sorted by packaging date
        fixes.each do |fix|
          Log.log_debug('  fix=' + fix)
          fix_filename = ::File.join(get_flrtvc_name(:common_efixes), fix)
          Log.log_debug('  fix_filename=' + fix_filename)
          Log.log_debug('  copying ' +
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
          Log.log_debug('  copied ' + fix_filename +
                            ' into ' + target_nimresource_dir_name)
        end

        # return hash with lpp_source as key and sorted ifix as value
        nim_lpp_source_resource = get_flrtvc_name(:NIM_res, target)
        Log.log_debug('  testing if NIM resource ' +
                          nim_lpp_source_resource + ' exists.')
        exists = Nim.lpp_source_exists?(nim_lpp_source_resource)
        Log.log_debug('  exists=' + exists.to_s +
                          ' exists.exitstatus=' + exists.exitstatus.to_s)
        if exists.exitstatus == 0
          Log.log_debug('  already built NIM resource ' +
                            nim_lpp_source_resource)
        else
          Log.log_debug('  building NIM resource ' +
                            nim_lpp_source_resource)
          Nim.define_lpp_source(nim_lpp_source_resource,
                                target_nimresource_dir_name)
          Log.log_debug('  built NIM resource ' +
                            nim_lpp_source_resource)
        end

        returned[nim_lpp_source_resource] = fixes
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
      def step_install_fixes(_step, target, nimres_sortedfixes)
        Log.log_debug('In step_install_fixes target=' + target +
                          '  nimres_sortedfixes=' +
                          nimres_sortedfixes.to_s)

        begin
          # efixes are sorted : most recent first
          nim_resource = nimres_sortedfixes.keys[0]
          ifixes = nimres_sortedfixes.values[0]
          ifixes_string = Utils.string_separated(ifixes, " ")

          # efixes are applied
          Log.log_debug('  performing ifix customization')
          Nim.perform_efix(target, nim_resource, ifixes_string)
          Log.log_debug('  performed ifix customization')
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
        Log.log_debug('In remove_nim_resources')
        @targets.each do |target|
          Log.log_debug('  target=' + target)
          nim_lpp_source_resource = get_flrtvc_name(:NIM_res, target)
          returned = Nim.lpp_source_exists?(nim_lpp_source_resource)
          Log.log_debug('  returned=' +
                            returned.to_s +
                            ' returned.exitstatus=' +
                            returned.exitstatus.to_s)
          if returned.exitstatus == 0
            Nim.remove_lpp_source(nim_lpp_source_resource)
            Log.log_debug('  removing NIM resource ' +
                              nim_lpp_source_resource)
          else
            Log.log_debug('  already removed NIM resource ' +
                              nim_lpp_source_resource)
          end
        end
      end

      # #######################################################################
      # name : remove_ifixes
      # return : nothing
      # description : For each target, uninstall ifix.
      # This is a convenient method used for tests, when we need to do some
      #  cycles of install efixes/uninstall efixes.
      # #######################################################################
      def remove_ifixes
        Log.log_debug('In remove_ifixes')
        @targets.each do |target|
          Log.log_debug('  target=' + target)
          nim_lpp_source_resource = get_flrtvc_name(:NIM_res, target)
          begin
            Log.log_debug('  removing ifixes')
            Nim.perform_efix_uncustomization(target, nim_lpp_source_resource)
            Log.log_debug('  removed ifixes')
          rescue StandardError => e
            Log.log_err('Exception e=' + e.to_s)
          end
        end
      end

      # #######################################################################
      # name : remove_downloaded
      # return : nothing
      # description : removes all ifix downloaded files (*.tar *.epkg.Z)
      # This is a convenient method used for tests, when we need to do some
      #  cycles of install efixes/uninstall efixes.
      # #######################################################################
      def remove_downloaded_files
        Log.log_debug('In remove_downloaded_files')
        begin
          Log.log_debug('  removing downloaded files')
          #  TBI
          Log.log_debug('  removed downloaded files')
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
      # return : hash with ifix file names as keys and boolean as values
      #     true if fix has been downloaded, false if it was already downloaded.
      #   If URL indicates a single epkg file, hash contains only one file
      #   If URL indicates a tar file, hash may contain more than one file
      #   If URL indicates a directory, hash may contain more than one file
      # description : URL may follow different formats,
      #  and this function adapts itself to these formats. Download is done if
      #  necessary only, if the file was already downloaded then it is
      #  not done again.
      # ########################################################################
      def download_fct(target, url_to_download, count, total)
        Log.log_debug('Into download_fct for target=' + target +
                          ' url_to_download=' + url_to_download +
                          ' count=' + count.to_s +
                          ' total=' + total.to_s)

        downloaded_filenames = {}
        unless %r{^(?<protocol>.*?)://(?<srv>.*?)/(?<dir>.*)/(?<name>.*)$} =~ url_to_download
          raise URLNotMatch "link: #{url_to_download}"
        end

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
              Log.log_debug('Into download_fct name.empty http/https')
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
                  b_download = false
                  response.body.each_line do |response_line|
                    next unless response_line =~ %r{<a href="(.*?.epkg.Z)">(.*?.epkg.Z)</a>}
                    url_of_file_to_download = ::File.join(url_to_download, Regexp.last_match(1))
                    local_path_of_file_to_download =
                        ::File.join(common_efixes_dirname, Regexp.last_match(1))
                    Log.log_debug(' consider downloading ' +
                                      url_of_file_to_download +
                                      ' into ' +
                                      common_efixes_dirname +
                                      " : #{count}/#{total} fixes.")
                    if !::File.exist?(local_path_of_file_to_download)
                    # if !File.zero?(local_path_of_file_to_download)
                      # File.zero returns false if file is not found or if file size is zero
                      # Download file
                      Log.log_debug("  downloading #{url_of_file_to_download} \
into #{common_efixes_dirname} and kept into\
                                    #{local_path_of_file_to_download}: #{count}/#{total} fixes.")
                      b_download = download(target,
                                            url_of_file_to_download,
                                            local_path_of_file_to_download,
                                            protocol)
                    else
                      Log.log_debug("  not downloading #{url_of_file_to_download}
into #{common_efixes_dirname} and kept into\
                                    #{local_path_of_file_to_download}: #{count}/#{total} fixes.")
                      b_download = false
                    end
                    downloaded_filenames[::File.basename(local_path_of_file_to_download)] =
                        b_download
                    subcount += 1
                  end
                  Log.log_debug('Into download_fct for target=' +
                                    target +
                                    ' http/https url_to_download=' +
                                    url_to_download +
                                    ', subcount=' +
                                    subcount.to_s)
                end
              rescue StandardError => std_error
                log "error sending event to server: #{std_error}"
                raise "standard error"

              rescue Timeout::Error => error
                log "timeout sending event to server: #{error}"
                raise "timeout error"

              end

            when 'ftp'
              # NEED TO BE TESTED AGAIN
              Log.log_debug('Into download_fct name.empty ftp')
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
          Log.log_debug('Into download_fct for target=' +
                            target +
                            ', !name.empty (name=' +
                            name +
                            ') and ends with .tar')
          #####################
          # URL is a tar file #
          #####################
          local_path_of_file_to_download = ::File.join(tar_dir, name)

          Log.log_debug(' Consider downloading ' +
                            url_to_download +
                            ' into ' +
                            tar_dir +
                            " : #{count}/#{total} fixes.")
          if !::File.exist?(local_path_of_file_to_download)
          # if !File.zero?(local_path_of_file_to_download)
            # File.zero returns false if file is not found or if file size is zero
            # download file
            Log.log_debug("  downloading #{url_to_download} \
into #{tar_dir}: #{count}/#{total} fixes.")
            b_download = download(target,
                                  url_to_download,
                                  local_path_of_file_to_download,
                                  protocol)

            if b_download
              # We untar only if the tar file does not yet exist.
              # We consider that if tar file already exists,
              #  then it has been already untarred.
              Log.log_debug("  untarring #{local_path_of_file_to_download} \
into #{temp_dir} : #{count}/#{total} fixes.")
              untarred_files = untar(local_path_of_file_to_download, temp_dir)
              # Log.log_debug("untarred_files = " + untarred_files.to_s)

              subcount = 1
              Log.log_debug('  copying ' + untarred_files.to_s + \
' into ' + common_efixes_dirname)
              untarred_files.each do |filename|
                # Log.log_debug("  copying filename " + filename
                #   +": #{count}.#{subcount}/#{total} fixes.")
                FileUtils.cp(filename, common_efixes_dirname)
                downloaded_filenames[::File.basename(filename)] = b_download
                subcount += 1
              end
            end
          else
            Log.log_debug("  not downloading #{url_to_download} \
into #{tar_dir}: #{count}/#{total} fixes.")
            tarfiles = tar_tf(local_path_of_file_to_download)
            tarfiles.each {|x| downloaded_filenames[::File.basename(x)] = false}
          end

        elsif name.end_with?('.epkg.Z')
          Log.log_debug('Into download_fct for target=' +
                            target +
                            ' !name.empty (name=' +
                            name +
                            ') and ends with .epkg.Z')
          #######################
          # URL is an efix file #
          #######################
          local_path_of_file_to_download =
              ::File.join(common_efixes_dirname, ::File.basename(name))
          Log.log_debug(' Consider downloading ' +
                            url_to_download +
                            ' into ' +
                            local_path_of_file_to_download +
                            " : #{count}/#{total} fixes.")
          if !::File.exist?(local_path_of_file_to_download)
          # if !File.zero?(local_path_of_file_to_download)
            # File.zero returns false if file is not found or if file size is zero
            # download file
            Log.log_debug("  downloading #{url_to_download} \
into #{local_path_of_file_to_download} : #{count}/#{total} fixes.")
            b_download = download(target,
                                  url_to_download,
                                  local_path_of_file_to_download,
                                  protocol)
          else
            Log.log_debug("  not downloading #{url_to_download} \
into #{local_path_of_file_to_download} \
: #{count}/#{total} fixes.")
            b_download = false
          end
          downloaded_filenames[::File.basename(local_path_of_file_to_download)] =
              b_download
        end

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
      # return : true if download has been done, false if download
      #   has been skipped
      # description : performs the download if the file is
      #  not yet downloaded.
      #  A retry mechanism which increases the file system size in
      #   case of ENOSPC
      # ########################################################################
      def download(target,
                   download_url,
                   destination_file,
                   protocol)
        Log.log_debug('  Into download(target=' + target +
                          ' download_url=' + download_url +
                          ' destination_file=' + destination_file +
                          ' protocol=' + protocol + ')')
        returned = false
        begin
          unless ::File.exist?(destination_file)
          Log.log_debug(::File.exist?(destination_file).to_s+" "+File.zero?(destination_file).to_s)
          #unless File.zero?(destination_file)
            ## File.zero returns false if file is not found or if file size is zero

            ::File.open(destination_file, 'w') do |f|
              download_expected = open(download_url)
              bytes_copied = ::IO.copy_stream(download_expected, f)
              if protocol != 'ftp'
                bytes_expected = download_expected.meta['content-length']
                if bytes_expected.to_i != bytes_copied
                  raise "Expected #{bytes_expected} \
bytes but got #{bytes_copied}"
                end
              end
              returned = true
            end
          end
        rescue Errno::ENOSPC => e
          ::File.delete(destination_file)
          Log.log_err('Automatically increasing file system \
as Exception e=' + e.to_s)
          Flrtvc.increase_filesystem(destination_file)
          return download(target, download_url, destination_file, protocol)
        rescue Errno::ETIMEDOUT => e
          ::File.delete(destination_file)
          Log.log_warning('Timeout while downloading :' + download_url)
          Log.log_err('Exception e=' + e.to_s + ':' + download_url + ' not downloaded')
          returned = false
            # TODO implement timeout on ftp download here, and a retry mechanism
        rescue StandardError => e
          ::File.delete(destination_file)
          Log.log_err('Exception e=' + e.to_s)
          Log.log_warning("Propagating exception of type \
'#{e.class}' when downloading!")
          raise e
        end
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
      def ftp_download(target, url_to_download,
                       count, total,
                       ftp_server, ftp_dir,
                       destination_dir)
        Log.log_debug('  Into download(target=' + target +
                          ' url_to_download=' + url_to_download +
                          ' count=' + count.to_s +
                          ' total=' + total.to_s +
                          ' ftp_server=' + ftp_server +
                          ' ftp_dir=' + ftp_dir +
                          ' destination_dir=' + destination_dir + ')')
        returned_downloaded_filenames = {}
        begin
          files_on_ftp_server = []
          Net::FTP.open(ftp_server) do |ftp|
            ftp.login
            ftp.read_timeout = 300
            ftp.chdir(ftp_dir)
            files_on_ftp_server = ftp.nlst('*.epkg.Z')
            subcount = 0

            files_on_ftp_server.each do |fileOnFtpServer|
              fix_to_download = ::File.join(url_to_download,
                                            ::File.basename(fileOnFtpServer))
              # download file
              local_path_of_file_to_download =
                  ::File.join(destination_dir,
                              ::File.basename(fileOnFtpServer))
              Log.log_debug(' Consider downloading ' +
                                fix_to_download +
                                ' into ' +
                                local_path_of_file_to_download +
                                " : #{count}.#{subcount}/#{total} fixes.")

              if !::File.exist?(local_path_of_file_to_download)
              # if !File.zero?(local_path_of_file_to_download)
                # File.zero returns false if file is not found or if file size is zero
                Log.log_debug('  downloading ' + fix_to_download +
                                  'into ' +
                                  local_path_of_file_to_download +
                                  " : #{count}.#{subcount}/#{total} fixes.")

                ftp.getbinaryfile(::File.basename(fileOnFtpServer),
                                  local_path_of_file_to_download)
                b_download = true
              else
                Log.log_debug('  not downloading ' +
                                  fix_to_download +
                                  'into ' +
                                  local_path_of_file_to_download +
                                  " : #{count}.#{subcount}/#{total} fixes.")
                b_download = false
              end

              subcount += 1

              returned_downloaded_filenames[::File.basename(local_path_of_file_to_download)] = b_download
              Log.log_debug('returned_downloaded_filenames=' + returned_downloaded_filenames.to_s)
            end
          end
        rescue Errno::ENOSPC => e
          Log.log_err('Automatically increasing file system \
when ftp_downloading as Exception e=' + e.to_s)
          Flrtvc.increase_filesystem(destination_dir)
          return ftp_download(target, url_to_download,
                              count, total,
                              ftp_server, ftp_dir,
                              destination_dir)
        rescue StandardError => e
          Log.log_err('Exception e=' + e.to_s)
          Log.log_warning("Propagating exception of type '#{e.class}' when ftp_downloading!")
          raise e
        end
        returned_downloaded_filenames
      end


      # ########################################################################
      # name : tar_tf
      # param : input:src:string
      # return : array of relative file names which belong to the tar file
      # description :
      # ########################################################################
      def tar_tf(file_to_untar)
        Log.log_debug('  Into tar_tf file_to_untar=' + file_to_untar)
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
        Log.log_debug('  Into tar_tf returned=' + returned.to_s)
        returned
      end

      # ########################################################################
      # name : untar
      # param : input:file_to_untar:string
      # param : input:directory_for_untar:string
      # return : array of absolute file names which have been untarred.
      # description : performs untar and returns result of untar
      # ########################################################################
      def untar(file_to_untar, directory_for_untar)
        Log.log_debug('  Into untar file_to_untar=' + file_to_untar +
                          ' directory_for_untar=' + directory_for_untar)
        returned = []
        begin
          command_output = []
          command = "/bin/tar -tf #{file_to_untar} | /bin/grep epkg.Z$"
          Utils.execute2(command, command_output)
          untarred_files_array = command_output[0].split("\n")
          untarred_files = Utils.string_separated(untarred_files_array,
                                                  ' ')

          cmd = "/bin/tar -xf #{file_to_untar} \
-C #{directory_for_untar} #{untarred_files}"
          Utils.execute(cmd)

          untarred_files_array.each do |untarred_file|
            absolute_untarred_file =
                ::File.join(directory_for_untar,
                            untarred_file)
            # Log.log_debug("  Into untar absolute_untarred_file=" +
            #   absolute_untarred_file)
            returned << absolute_untarred_file
          end
        rescue Exception => e
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
        Log.log_debug('  Into untar returned=' + returned.to_s)
        returned
      end

      # #######################################################################
      # name : min_max_level_prereq_of
      # param : input:fixfile:string
      #
      # return : hash with lpp as keys and [min, max] as values, for all lpp
      #   impacted by the ifix
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
              Log.log_debug('  fixfile=' + fixfile +
                                ' lpp=' + lpp.to_s +
                                ' splevel_min=' + splevel_min.to_s +
                                ' splevel_min=' + splevel_max.to_s)
              returned[lpp] = [splevel_min, splevel_max]
            end
          else
            Log.log_debug('  No prereq set on this fix')
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
            output_to_regex = command_output[0].chomp
            Log.log_debug('output_to_regex=' + output_to_regex + "|")
            output_to_regex =~ %r{PACKAGING DATE:\s+\w+\s+(\w+)\s+(\d+)\s+(\d+):(\d+):(\d+)\s+\w+\s+(\d+)\s*}
            #                                               0       1       2     3    4              5
            hash_months = {"Jan" => "01", "Feb" => "02", "Mar" => "03",
                           "Apr" => "04", "May" => "05", "Jun" => "06",
                           "Jul" => "07", "Aug" => "08", "Sep" => "09",
                           "Oct" => "10", "Nov" => "11", "Dec" => "12"}
            #
            month = Regexp.last_match(1)
            #Log.log_debug('month=' + month.to_s)
            s_month = hash_months[month.to_s]
            #Log.log_debug('s_month=' + s_month.to_s)

            #
            day = Regexp.last_match(2)
            #Log.log_debug('day=' + day.to_s)
            if day.to_i <= 9
              s_day = "0" + day.to_s
            else
              s_day = day.to_s
            end
            #Log.log_debug('s_day=' + s_day)

            #
            hour = Regexp.last_match(3)
            minute = Regexp.last_match(4)
            second = Regexp.last_match(5)

            #
            year = Regexp.last_match(6)

            #
            packaging_date = year + '_' + s_month + '_' + s_day + '_' +
                hour.to_s + '_' + minute.to_s + '_' + second.to_s
            Log.log_debug('  packaging_date=' + packaging_date)
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
      # name : is_level_prereq_ok?
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
      def is_level_prereq_ok?(target, lpp, min, max)
        Log.log_debug('  Into is_level_prereq_ok? target=' +
                          target +
                          ', lpp=' +
                          lpp +
                          ', min=' +
                          min.to_s +
                          ', max=' +
                          max.to_s)
        # By default we return true, meaning the fix can be applied
        returned = true

        begin
          lslpp_file = get_flrtvc_name(:lslpp, target)
          command_output = []
          # environment: {'LANG' => 'C'}
          Utils.execute2("/bin/cat #{lslpp_file} | /bin/grep -w #{lpp} | /bin/cut -d: -f3",
                         command_output)
          lvl_a = command_output[0].split('.')
          lvl = SpLevel.new(lvl_a[0], lvl_a[1], lvl_a[2], lvl_a[3])
          #
          Log.log_debug('   Into is_level_prereq_ok? target=' +
                            target +
                            ' lvl=' +
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
        mount = mounts.sort_by!(&:length).reverse!.detect {|mnt| path =~ /#{Regexp.quote(mnt.to_s)}/}

        # Then increase by 100 MB
        command_output = []
        Utils.execute2("/usr/sbin/chfs -a size=+100M #{mount}",
                       command_output)
        Log.log_debug('command_output=' + command_output[0])
      end
    end

    class FlrtvcNotFound < StandardError
    end

    class URLNotMatch < StandardError
    end

    class InvalidAparProperty < StandardError
    end

    class InvalidCsvProperty < StandardError
    end
  end
end
