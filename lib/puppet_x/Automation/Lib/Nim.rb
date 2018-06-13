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
        Log.log_info('Nim.cust_install operation')
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
        Log.log_info('Nim.cust_update operation')
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
      # param : input:filesets:string
      # param : input:installp_flags:string
      # param : input:sync_option:string
      # param : input:targets:array of strings
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
        Log.log_info('Nim.maint operation')
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
        Log.log_info('Nim.reboot operation')
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
      # description : patch target with ifixes
      # #######################################################################
      def self.perform_efix(target,
          lpp_source,
          filesets = 'all')
        Log.log_info('Nim.perform_efix target=' +
                         target +
                         ' lpp_source=' +
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
      # name : perform_efix_uncustomization
      # param : input:target:string
      # param : input:lpp_source:string  not used
      # return :
      # description : uninstall all efixes on this target
      # #######################################################################
      def self.perform_efix_uncustomization(target,
          lpp_source)
        Log.log_info('Nim.perform_efix_uncustomization target=' + \
target + ' lpp_source=' + lpp_source)
        #
        Log.log_debug('Building list of efixes to be removed')
        remote_cmd = '/usr/sbin/emgr -P  | /usr/bin/tail -n +4'
        remote_output = []
        remote_cmd_status = Remote.c_rsh(target, remote_cmd, remote_output)
        if remote_cmd_status.success? && !remote_output[0].nil? && !remote_output[0].empty?
          # here is the remote command output parsing method
          cmd = "/bin/echo \"#{remote_output[0]}\" | /bin/awk '{print $3}' | /bin/sort -u"
          stdout, stderr, status = Open3.capture3(cmd)
          Log.log_debug("cmd   =#{cmd}")
          Log.log_debug("status=#{status}") if !status.nil?
          if status.success?
            if !stdout.nil? && !stdout.strip.empty?
              nb_of_ifixes = stdout.lines.count
              Log.log_debug("stdout=#{stdout}" + ' nb_of_ifixes=' +
                                nb_of_ifixes.to_s)
              Log.log_debug("Removing efixes on #{target}.")
              index_ifix = 1
              stdout.each_line.each do |efix|
                next unless !efix.nil? && !efix.strip.empty?
                Log.log_debug('Removing (' + index_ifix.to_s + '/' +
                                  nb_of_ifixes.to_s + ') ' + efix)
                remote_cmd = '/usr/sbin/emgr -r -L ' + efix
                remote_cmd_status = Remote.c_rsh(target,
                                                 remote_cmd,
                                                 remote_output)
                if remote_cmd_status.success?
                  Log.log_debug(" ok stdout = #{remote_output[0]}")
                else
                  Log.log_err("ko stderr=#{remote_output[0]}")
                end
                Log.log_debug('Removed efix ' + efix)
                index_ifix += 1
              end
              Log.log_debug("Finish removing ifixes on #{target}.")
            else
              Log.log_debug("No ifixes to remove on #{target}.")
            end
          elsif !stderr.nil? && !stderr.strip.empty?
            Log.log_err("stderr=#{stderr}")
          end
        else
          Log.log_debug("No ifixes to remove on #{target}.")
        end
      end

      # ########################################################################
      # name : perform_efix_vios
      # param : input:lpp_source:string
      # param : input:vios:string
      # param : input:_filesets:string
      # return :
      # description : patch vios with ifixes
      # ########################################################################
      def perform_efix_vios(lpp_source,
                            vios,
                            _filesets = 'all')
        Log.log_info('Nim.perform_efix_vios')
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
        Log.log_info('Nim.define_lpp_source')
        #
        nim_command = "/usr/sbin/nim -o define -t lpp_source -a server=master \
-a location=#{directory} -a packages=all \
-a comments='#{comments}' #{lpp_source}"
        Utils.execute(nim_command)
      end

      # #######################################################################
      # name : lpp_source_exists?
      # param : input:lpp_source:string
      # return :
      # description : tests if NIM lpp_source already exists or not
      # #######################################################################
      def self.lpp_source_exists?(lpp_source)
        Log.log_info('Nim.lpp_source_exists?')
        #
        nim_command = "/usr/sbin/lsnim | grep -w \"#{lpp_source}\""
        returned = Utils.execute(nim_command)
        Log.log_info('Nim.lpp_source_exists? returned=' + returned.to_s)
        returned
      end

      # #######################################################################
      # name : remove_lpp_source
      # param : input:lpp_source:string
      # return :
      # description : removes the NIM lpp_source resource.
      # #######################################################################
      def self.remove_lpp_source(lpp_source)
        Log.log_info('Nim.remove_lpp_source')
        #
        nim_command = '/usr/sbin/nim -o remove ' + lpp_source
        Utils.execute(nim_command)
      end

      # #######################################################################
      # name : sort_ifixes
      # param : input:lpp_source:string
      # return : string containing the ifixes sorted
      #   in reverse order : the more recent first
      # description : sort ifixes of lpp_source in reverse order
      # #######################################################################
      def self.sort_ifixes(lpp_source)
        Log.log_info('Nim.sort_ifixes')
        #
        returned = ''
        nim_command1 = "/usr/sbin/lsnim -a location #{lpp_source} | /bin/grep -w location | /bin/awk '{print $3}'"
        nim_command_output1 = []
        Utils.execute2(nim_command1, nim_command_output1)
        #
        unless nim_command_output1.nil?
          nim_command2 = "/bin/ls #{nim_command_output1[0].chomp} | /bin/sort -ru"
          nim_command_output2 = []
          Utils.execute2(nim_command2, nim_command_output2)
          unless nim_command_output2.nil?
            Log.log_info('Nim.sort_ifixes returned=' + nim_command_output2[0].to_s)
            returned = nim_command_output2[0].gsub('\n', ' ')
          end
        end
        returned
      end
    end # Nim

    # ############################
    #     E X C E P T I O N      #
    # ############################
    class NimHmcInfoError < StandardError
    end
    #
    class NimLparInfoError < StandardError
    end
    #
    class NimAltDiskInstallError < StandardError
    end
    #
    class NimAltDiskInstallTimedOut < StandardError
    end
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
