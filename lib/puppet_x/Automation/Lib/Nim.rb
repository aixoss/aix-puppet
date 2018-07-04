module Automation
  module Lib
    # ########################################################################
    # Class Nim
    # ########################################################################
    #  NIM class implementation with methods to perform
    #   install, update, reboot, ...
    # ########################################################################
    class Nim
      # #######################################################################
      # name : cust_install
      # param : input:lpp_source:string
      # param : input:sync_option:string
      # param : input:targets_array:array of strings
      # return :
      # description : prepares the NIM command to be run
      #   and calls Utils.execute().
      #  Performs installation of lpp_source.
      # #######################################################################
      def self.cust_install(lpp_source,
          sync_option,
          targets_array)
        Log.log_debug('Nim.cust_install operation')
        #
        targets = Utils.string_separated(targets_array, ' ')
        nim_command = "/usr/sbin/nim -o cust -a lpp_source=#{lpp_source} \
-a #{sync_option} -a filesets=all -a installp_flags=acNgXY " + targets
        Utils.execute(nim_command)
      end

      # #######################################################################
      # name : cust_update
      # param : input:lpp_source:string
      # param : input:sync_option:string
      # param : input:installp_flags:string
      # param : input:targets_array:array of strings
      # return :
      # description : prepares the NIM command to be run
      #   and calls Utils.execute().
      #  Performs update of a system from a lpp_source.
      # #######################################################################
      def self.cust_update(lpp_source,
          sync_option,
          installp_flags,
          targets_array)
        Log.log_debug('Nim.cust_update operation')
        #
        option_installp_flags = ''
        unless installp_flags.empty?
          option_installp_flags = ' -a installp_flags=' + installp_flags
        end
        targets = Utils.string_separated(targets_array, ' ')
        nim_command = "/usr/sbin/nim -o cust -a lpp_source=#{lpp_source} \
-a #{sync_option} -a fixes=update_all \
-a accept_licenses=yes #{option_installp_flags} " + targets
        Utils.execute(nim_command)
      end

      # #######################################################################
      # name : maint
      # param : input:filesets:string
      # param : input:sync_option:string
      # param : input:installp_flags:string
      # param : input:targets_array:array of strings
      # return :
      # description : prepares the NIM command to be run
      #   and calls Utils.execute().
      #  Performs maintenance operations on filesets,
      #   depending on installp_flags it can be apply,reject,commit
      # #######################################################################
      def self.maint(filesets,
          sync_option,
          installp_flags,
          targets_array)
        Log.log_debug('Nim.maint operation')
        #
        targets = Utils.string_separated(targets_array, ' ')
        nim_command = "/usr/sbin/nim -o maint -a filesets=#{filesets} \
-a #{sync_option} -a installp_flags=#{installp_flags}\
        " + targets
        Utils.execute(nim_command)
      end

      # #######################################################################
      # name : reboot
      # param : input:targets_array:array of strings
      # return :
      # description : prepares the NIM command to be run
      #   and calls Utils.execute().
      #  Performs reboot of systems.
      # #######################################################################
      def self.reboot(targets_array)
        Log.log_debug('Nim.reboot operation')
        #
        targets = Utils.string_separated(targets_array, ' ')
        nim_command = '/usr/sbin/nim -o reboot ' + targets + ' &'
        Utils.execute(nim_command)
      end

      # #######################################################################
      # name : perform_efix
      # param : input:target:string
      # param : input:lpp_source:string
      # param : input:filesets:string
      # return :
      # description : patch target with efixes
      # #######################################################################
      def self.perform_efix(target,
          lpp_source,
          filesets = 'all')
        Log.log_debug('Nim.perform_efix (target=' +
                          target +
                          ') lpp_source=' +
                          lpp_source)
        #
        # nim -o cust -a filesets=E:IZ12345.epkg.Z -a lpp_source=lpp1 spot1
        nim_command = "/usr/sbin/nim -o cust -a lpp_source=#{lpp_source} \
-a filesets='#{filesets}' #{target}"
        Log.log_debug("NIM install efixes cust operation: #{nim_command}")
        Log.log_debug("Start patching machine(s) '#{target}'.")
        Open3.popen3({ 'LANG' => 'C' }, nim_command) \
do |_stdin, stdout, stderr, wait_thr|
          thr = Thread.new do
            loop do
              print '.'
              sleep 3
            end
          end
          stdout.each_line do |line|
            line.chomp!
            Log.log_debug("\033[2K\r#{line}") if line =~ /^Processing Efix Package [0-9]+ of [0-9]+.$/
            Log.log_debug("\n#{line}") if line =~ /^EPKG NUMBER/
            Log.log_debug("\n#{line}") if line =~ /^===========/
            Log.log_debug("\033[0;31m#{line}\033[0m") if line =~ /INSTALL.*?FAILURE/
            Log.log_debug("\033[0;32m#{line}\033[0m") if line =~ /INSTALL.*?SUCCESS/
          end
          stderr.each_line do |line|
            line.chomp!
            Log.log_err(" #{line} !")
          end
          unless stderr.nil?
            Log.log_err(' To better understand error case, you should refer to remote file ' + target + ':/var/adm/ras/emgr.log')
          end
          thr.exit
          wait_thr.value # Process::Status object returned.
        end
        Log.log_debug("Finish patching #{target}.")
      end

      # #######################################################################
      # name : perform_efix_uninstallation
      # param : input:target:string
      # param : input:lpp_source:string  not used
      # return :
      # description : uninstall all efixes on this target
      # #######################################################################
      def self.perform_efix_uninstallation(target,
          lpp_source)
        Log.log_debug('Nim.perform_efix_uninstallation (target=' + \
target + ') lpp_source=' + lpp_source)
        #
        Log.log_debug('Building list of efixes to be removed')
        returned = true
        remote_cmd = '/usr/sbin/emgr -P | /usr/bin/tail -n +4'
        remote_output = []
        remote_cmd_rc = Remote.c_rsh(target, remote_cmd, remote_output)
        if remote_cmd_rc == 0 &&
            !remote_output[0].nil? &&
            !remote_output[0].empty?
          # here is the remote command output parsing method
          cmd = "/bin/echo \"#{remote_output[0]}\" | /bin/awk '{print $3}' | /bin/sort -u"
          stdout, stderr, status = Open3.capture3(cmd)
          Log.log_debug("cmd   =#{cmd}")
          Log.log_debug("status=#{status}") unless status.nil?
          if status.success?
            if !stdout.nil? && !stdout.strip.empty?
              nb_of_efixes = stdout.chomp.lines.count - 1
              Log.log_debug("stdout=#{stdout}" + ' nb_of_efixes=' +
                                nb_of_efixes.to_s)
              Log.log_debug("Removing efixes on #{target}.")
              index_efix = 1
              nb_removed_efix = 0
              nb_not_removed_efix = 0
              stdout.each_line.each do |efix|
                next unless !efix.nil? && !efix.strip.empty?
                efix = efix.chomp
                Log.log_info('Removing (' + index_efix.to_s + '/' +
                                  nb_of_efixes.to_s + ') ' + efix)
                remote_cmd = '/usr/sbin/emgr -r -L ' + efix
                remote_cmd_rc = Remote.c_rsh(target,
                                             remote_cmd,
                                             remote_output)
                if remote_cmd_rc == 0
                  Log.log_debug(" ok stdout = #{remote_output[0]}")
                  Log.log_info('Removed efix ' + efix)
                  nb_removed_efix += 1
                else
                  Log.log_err("ko stderr=#{remote_output[0]}")
                  Log.log_err('efix ' + efix + ' not removed')
                  nb_not_removed_efix += 1
                  returned = false
                end
                index_efix += 1
              end
              log_msg = 'Finish processing removing of efixes on ' + target +
                  ':' + nb_removed_efix.to_s + '/' + nb_of_efixes.to_s + ' removed,' +
                  nb_not_removed_efix.to_s + '/' + nb_of_efixes.to_s + ' not removed '
              if returned
                Log.log_debug(log_msg)
              else
                Log.log_err(log_msg)
              end
            else
              Log.log_debug("No efixes to remove on #{target}.")
            end
          elsif !stderr.nil? && !stderr.strip.empty?
            Log.log_err("stderr=#{stderr}")
          end
        else
          Log.log_debug("No efixes to remove on #{target}.")
        end
        returned
      end

      # ########################################################################
      # name : perform_efix_vios
      # param : input:lpp_source:string
      # param : input:vios:string
      # param : input:_filesets:string
      # return :
      # description : patch vios with efixes
      # ########################################################################
      def perform_efix_vios(lpp_source,
                            vios,
                            _filesets = 'all')
        Log.log_debug('Nim.perform_efix_vios')
        nim_command = "/usr/sbin/nim -o updateios -a preview=no \
-a lpp_source=#{lpp_source} #{vios}"
        #
        Log.log_debug("NIM updateios operation: #{nim_command}")
        Log.log_debug("Start patching machine(s) '#{vios}'.")
        exit_status = Open3.popen3({ 'LANG' => 'C' }, nim_command) do |_stdin, stdout, stderr, wait_thr|
          thr = Thread.new do
            loop do
              print '.'
              sleep 3
            end
          end
          stdout.each_line do |line|
            line.chomp!
            Log.log_debug("\033[2K\r#{line}") if line =~ /^Processing Efix Package [0-9]+ of [0-9]+.$/
            Log.log_debug("\n#{line}") if line =~ /^EPKG NUMBER/
            Log.log_debug("\n#{line}") if line =~ /^===========/
            Log.log_debug("\033[0;31m#{line}\033[0m") if line =~ /INSTALL.*?FAILURE/
            Log.log_debug("\033[0;32m#{line}\033[0m") if line =~ /INSTALL.*?SUCCESS/
          end
          stderr.each_line do |line|
            line.chomp!
            Log.log_err(" #{line} !")
          end
          unless stderr.nil?
            Log.log_err(' To better understand error case, you should refer to remote file ' + target +
                            ':/var/adm/ras/emgr.log')
          end
          thr.exit
          wait_thr.value # Process::Status object returned.
        end
        Log.log_debug("Finish patching #{vios}.")
        raise NimCustOpError, "Error: Command \"#{nim_command}\" returns \
above error!" unless exit_status.success?
      end

      # #######################################################################
      # name : define_lpp_source
      # param : input:lpp_source:string
      # param : input:directory:string
      # param : input:comments:string
      # return :
      # description : defines the NIM lpp_source resource.
      # #######################################################################
      def self.define_lpp_source(lpp_source,
          directory,
          comments = 'Built by Puppet AixAutomation')
        Log.log_debug('Nim.define_lpp_source')
        #
        nim_command = "/usr/sbin/nim -o define -t lpp_source -a server=master \
-a location=#{directory} -a packages=all \
-a comments='#{comments}' #{lpp_source}"
        return_code = Utils.execute(nim_command)
        #
        Log.log_debug('Nim.define_lpp_source return_code=' + return_code.to_s)
        return_code
      end

      # #######################################################################
      # name : lpp_source_exists?
      # param : input:lpp_source:string
      # return : true if it exists, false otherwise
      # description : tests if NIM lpp_source already exists or not
      # #######################################################################
      def self.lpp_source_exists?(lpp_source)
        Log.log_debug('Nim.lpp_source_exists?')
        returned = true
        #
        nim_command = "/usr/sbin/lsnim | grep -w \"#{lpp_source}\""
        return_code = Utils.execute(nim_command)
        #
        Log.log_debug('Nim.lpp_source_exists? return_code=' + return_code.to_s)
        if return_code == 1
          returned = false
        end
        returned
      end

      # #######################################################################
      # name : remove_lpp_source
      # param : input:lpp_source:string
      # return :
      # description : removes the NIM lpp_source resource.
      # #######################################################################
      def self.remove_lpp_source(lpp_source)
        Log.log_debug('Nim.remove_lpp_source')
        #
        nim_command = '/usr/sbin/nim -o remove ' + lpp_source
        return_code = Utils.execute(nim_command)
        #
        Log.log_debug('Nim.remove_lpp_source return_code=' + return_code.to_s)
        return_code
      end

      # #######################################################################
      # name : get_location_of_lpp_source
      # param : input:lpp_source:string
      # return : string containing the location sorted
      # description : get location of NIM lpp_source resource
      # #######################################################################
      def self.get_location_of_lpp_source(lpp_source)
        Log.log_debug('Nim.get_location_of_lpp_source')
        #
        returned = ''
        nim_command = "/usr/sbin/lsnim -a location #{lpp_source} | /bin/grep -w location | /bin/awk '{print $3}'"
        nim_command_output = []
        return_code = Utils.execute2(nim_command, nim_command_output)
        Log.log_debug('Nim.get_location_of_lpp_source return_code=' + return_code.to_s)
        #
        unless nim_command_output.nil?
          if nim_command_output[0].to_s =~ /^0042-053 lsnim: there is no NIM object named.$/
            #
          else
            returned = nim_command_output[0].chomp.to_s
          end
        end
        returned
      end

      # #######################################################################
      # name : sort_efixes
      # param : input:lpp_source:string
      # return : string containing the efixes sorted
      #   in reverse order : the more recent first
      # description : sort efixes of lpp_source in reverse order
      # #######################################################################
      def self.sort_efixes(lpp_source)
        Log.log_debug('Nim.sort_efixes')
        #
        returned = ''
        location = Nim.get_location_of_lpp_source(lpp_source)
        #
        unless location.nil? || location.empty?
          nim_command = "/bin/ls #{location} | /bin/sort -ru"
          nim_command_output = []
          return_code = Utils.execute2(nim_command, nim_command_output)
          Log.log_debug('Nim.sort_efixes return_code=' + return_code.to_s)
          #
          unless nim_command_output.nil?
            Log.log_debug('Nim.sort_efixes returned=' + nim_command_output[0].to_s)
            returned = nim_command_output[0].gsub('\n', ' ')
          end
        end
        returned
      end
    end # Nim

    # ############################
    #     E X C E P T I O N      #
    # ############################
    #
    class NimError < StandardError
    end
    #
    class NimCustOpError < NimError
    end
    #
    class NimMaintOpError < NimError
    end
    #
    class NimDefineError < NimError
    end
    #
    class NimRemoveError < NimError
    end
    #
    class NimRebootOpError < NimError
    end
    #
  end
end
