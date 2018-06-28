require_relative './Remote/c_rsh.rb'
require 'open3'

module Automation
  module Lib
    # ##########################################################################
    # name : Utils class
    # description : collection of general-purpose utility class methods
    # All these methods are independent from Puppet framework
    # ##########################################################################
    class Utils
      # ########################################################################
      # name : execute
      # param : input:command:string
      # return : int return code
      # description : executes (by using Open3.popen3)
      #   command received in parameter.
      #  This method is a convenience used by all other methods.
      # ########################################################################
      def self.execute(command)
        Log.log_debug('Utils.execute command : ' + command)
        #
        Open3.popen3({ 'LANG' => 'C' }, command) do |_stdin, stdout, stderr, wait_thr|
          #
          stdout.each_line do |line|
            Log.log_debug(line.chomp.to_s)
          end
          #
          stderr.each_line do |line|
            Log.log_err(line.chomp.to_s)
          end
          Log.log_debug('Utils.execute wait_thr.value(' +
                            wait_thr.value.class.to_s + ')="' +
                            wait_thr.value.to_s +
                            '" wait_thr.value.exitstatus ="' +
                            wait_thr.value.exitstatus.to_s +
                            '"')
          # wait_thr.value : Process::Status object returned.
          # wait_thr.value.exitstatus : int
          wait_thr.value.exitstatus
        end
      end

      # ########################################################################
      # name : execute2
      # param : input:command:string
      # param : output:command_output: array of strings
      # return : int return code
      # description : executes (by using Open3.popen3)
      #   command received in parameter,
      #   and set the command_output[0] param as output parameter
      #  This method is a convenience used by all other methods.
      # ########################################################################
      def self.execute2(command,
          command_output)
        Log.log_debug('Utils.execute2 command : ' + command)
        #
        Open3.popen3({ 'LANG' => 'C' }, command) do |_stdin, stdout, stderr, wait_thr|
          command_output[0] = ''
          stdout.each_line do |line|
            command_output[0] = command_output[0] + line
            Log.log_debug("    #{line.chomp}")
          end
          stderr.each_line do |line|
            Log.log_err("    #{line.chomp}")
          end
          Log.log_debug('Utils.execute2 wait_thr.value(' +
                            wait_thr.value.class.to_s + ')="' +
                            wait_thr.value.to_s +
                            '" wait_thr.value.exitstatus ="' +
                            wait_thr.value.exitstatus.to_s +
                            '"')
          # wait_thr.value : Process::Status object returned.
          # wait_thr.value.exitstatus : int
          wait_thr.value.exitstatus
        end
      end

      # ########################################################################
      # name : check_input_lppsource
      # param :input:lppsource:string
      # return :status
      # description : checks lppsource is valid
      # ########################################################################
      def self.check_input_lppsource(lppsource)
        Log.log_debug('Into check_input_lppsource lppsource=' + lppsource)
        #
        if !lppsource.empty?
          cmd = "/usr/sbin/lsnim -l #{lppsource}"
          stdout, stderr, status = Open3.capture3(cmd.to_s)
          Log.log_debug("cmd   =#{cmd}")
          if !stdout.nil? && !stdout.strip.empty?
            Log.log_debug("stdout=#{stdout}")
          end
          if !stderr.nil? && !stderr.strip.empty?
            Log.log_err("stderr=#{stderr}")
          end
          unless status.nil?
            Log.log_debug("status=#{status}")
          end
          unless status.success?
            Log.log_err("This \"#{lppsource}\" lppsource does not exist as simple NIM resource.")
          end
        else
          Log.log_debug("This \"#{lppsource}\" lppsource parameter is empty.")
          status = nil # how to set a Process:status to failure ?
        end
        Log.log_debug('Ending check_input_lppsource ' + status.to_s)
        status
      end

      # ########################################################################
      # name : check_input_targets
      # param :input:targets:string
      # param :output:kept:array of strings
      # param :output:suppressed:array of strings
      # return : 2 output params
      # description : checks 'targets' string contain valid target
      #               returns in 'kept' the valid targets
      #               returns in 'suppressed' the invalid targets
      # ########################################################################
      def self.check_input_targets(targets,
          kept,
          suppressed)
        Log.log_debug('Into check_input_targets targets=' + targets.to_s +
                          ' kept=' + kept.to_s +
                          ' suppressed=' + suppressed.to_s)
        #
        targets_list = targets.to_s.split(/\W+/)
        Log.log_debug("targets_list=#{targets_list}")
        #
        standalones = Facter.value(:standalones)
        standalones_keys = standalones.keys
        targets_list.each do |target|
          if !target.empty?
            if standalones_keys.include? target
              kept.push(target.to_s)
            else
              Log.log_warning("This \"#{target}\" target is not part of standalones \
: cannot be kept.")
              suppressed.push(target.to_s)
            end
          else
            Log.log_err("This \"#{target}\" target parameter is empty.")
            suppressed.push(target.to_s)
          end
        end
        Log.log_debug('Ending check_input_targets kept=' + kept.to_s)
      end

      # ########################################################################
      # name : check_directory
      # param :input:directory:string
      # return :0 if ok, -1 otherwise
      # description : checks directory exists, create it otherwise
      # ########################################################################
      def self.check_directory(directory)
        #
        returned = -1
        if !directory.empty?
          cmd = "/bin/mkdir -p #{directory}"
          stdout, stderr, status = Open3.capture3(cmd.to_s)
          if !status.success?
            if !stderr.nil? && !stderr.strip.empty?
              Log.log_err("stderr=#{stderr}")
            end
            Log.log_err("This \"#{directory}\" directory cannot be created.")
          else
            if !stdout.nil? && !stdout.strip.empty?
              Log.log_debug("stdout=#{stdout}")
            end
            returned = 0
          end
        else
          Log.log_err("This \"#{directory}\" directory parameter is empty.")
        end

        returned
      end

      # ########################################################################
      # name : get_filesets_of_lppsource
      # param :input:lppsource:string
      # return :filesets of a given lppsource:string (blank separated)
      # description : returns the filesets of a given lppsource
      #  so that we can uninstall them, or we can reject them
      # ########################################################################
      def self.get_filesets_of_lppsource(lppsource)
        Log.log_debug('Into get_filesets_of_lppsource lppsource=' + lppsource)
        #
        cmd = "/usr/sbin/nim -o showres #{lppsource}"
        # suppress empty lines, commented lines, and 2 first lines
        stdout, stderr, status = Open3.capture3("#{cmd} | /bin/egrep -v '=====|Fileset Name|#|^$' | /bin/awk '{print $1}'")
        Log.log_debug("cmd   =#{cmd}")
        Log.log_debug("status=#{status}") unless status.nil?
        returned = ''
        if status.success?
          if !stdout.nil? && !stdout.strip.empty?
            Log.log_debug("stdout=#{stdout}")
          end
          #
          items = stdout.split("\n")
          returned = string_separated(items, ' ')
        elsif !stderr.nil? && !stderr.strip.empty?
          Log.log_err("stderr=#{stderr}")
        end
        Log.log_debug('Ending get_filesets_of_lppsource ' + returned)
        returned
      end

      # ########################################################################
      # name : get_applied_filesets
      # param : input:target:string
      # return : stdout or stderr
      # description : returns the list of applied filesets
      #  so that we can either commit them, or reject them
      # ########################################################################
      def self.get_applied_filesets(target)
        Log.log_debug('Into get_applied_filesets target=' + target)
        #
        remote_cmd = '/bin/lslpp -lcq | /bin/grep -w APPLIED'
        remote_output = []
        remote_cmd_rc = Remote.c_rsh(target, remote_cmd, remote_output)
        if remote_cmd_rc == 0
          # here is the remote command output parsing method
          cmd = "/bin/echo \"#{remote_output[0]}\" | /bin/awk '{print $1}' | /bin/sort -u"
          stdout, stderr, status = Open3.capture3(cmd)
          Log.log_debug("cmd   =#{cmd}")
          Log.log_debug("status=#{status}") unless status.nil?
          if status.success?
            if !stdout.nil? && !stdout.strip.empty?
              Log.log_debug("stdout=#{stdout}")
            end
            Log.log_debug('Ending get_applied_filesets ' + stdout)
            stdout
          else
            if !stderr.nil? && !stderr.strip.empty?
              Log.log_err("stderr=#{stderr}")
            end
            Log.log_err('Ending get_applied_filesets ' + stderr)
            stderr
          end
        end
      end

      # ########################################################################
      # name : get_applied_filesets2
      # param :input:target:string
      # param :output:filesets:string (blank separated)
      # return :status
      # description : if status.success, then
      #   returns the list of applied filesets so that we can reject them
      # ########################################################################
      def self.get_applied_filesets2(target,
          filesets)
        Log.log_debug('Into get_applied_filesets2 target=' +
                          target +
                          ' filesets=' +
                          filesets.to_s)
        remote_cmd = '/bin/lslpp -lcq | /bin/grep -w APPLIED'
        remote_output = []
        remote_cmd_rc = Remote.c_rsh(target,
                                     remote_cmd,
                                     remote_output)
        if remote_cmd_rc == 0
          # here is the remote command output parsing method
          stdout, stderr, status =
              Open3.capture3("/bin/echo \"#{remote_output[0]}\" | /bin/awk -F ':' '{print $2}' | /bin/sort -u")
          Log.log_debug("status=#{status}") unless status.nil?
          if status.success?
            if !stdout.nil? && !stdout.strip.empty?
              Log.log_debug("stdout=#{stdout}")
            end
            # items = []
            items = stdout.split("\n")
            filesets[0] = string_separated(items, ' ')
          elsif !stderr.nil? && !stderr.strip.empty?
            Log.log_err("stderr=#{stderr}")
          end
          Log.log_debug('Ending get_applied_filesets2 : ' +
                            status.to_s)
          status
        else
          Log.log_err('Error while doing c_rsh ' +
                          remote_cmd +
                          ' on ' +
                          target)
        end
      end

      # ########################################################################
      # name : get_targets_applied_filesets
      # param :input:targets:array of strings
      # return :hash:target as keys, and applied filesets as values
      #         applied filesets are returned as string (blank separated)
      # description : returns hash of applied filesets per target
      #  so that we can either commit them, or reject them.
      # ########################################################################
      def self.get_targets_applied_filesets(targets)
        Log.log_debug('Into get_targets_applied_filesets targets=' +
                          targets.to_s)
        remote_output_per_target = {}
        targets.each do |target|
          output_filesets = []
          get_applied_filesets2(target, output_filesets)
          remote_output_per_target[target] = output_filesets[0]
        end
        Log.log_debug('Ending get_targets_applied_filesets : ' +
                          remote_output_per_target.to_s)
        remote_output_per_target
      end

      # ########################################################################
      # name : string_separated
      # param : input:array_of_items:[]
      # param : input:separator:strin, blanck by default
      # return : string containing items separated, separator is second param
      # description : takes an array with items, returns a
      #   string with items separated
      # ########################################################################
      def self.string_separated(array_of_items,
          separator)
        # Log.log_debug("Into string_separated array_of_items=" +
        #   array_of_items.to_s + " separator=" + separator)
        #
        returned_string_separated = ''
        array_of_items.each do |item|
          returned_string_separated = if returned_string_separated.empty?
                                        item
                                      else
                                        returned_string_separated + separator + item
                                      end
        end
        # Log.log_debug("Ending string_separated : " +
        #    returned_string_separated)
        returned_string_separated
      end

      # ########################################################################
      # name : check_install_flrtvc
      # param : none
      # return : 0 if everything is ok,
      # description : check if /usr/bin/flrtvc.ksh is installed or not and
      #  install it if necessary
      # ########################################################################
      def self.check_install_flrtvc
        Log.log_debug('Into check_install_flrtvc')
        #
        returned = 0
        unless ::File.exist?('/usr/bin/flrtvc.ksh')
          Log.log_debug('/usr/bin/flrtvc.ksh does not exist')
          unless ::File.exist?('/tmp/FLRTVC-latest.zip')
            Log.log_debug('/tmp/FLRTVC-latest.zip does not exist')
            ::File.open('/tmp/FLRTVC-latest.zip', 'w') do |f|
              download_expected = open('https://www-304.ibm.com/webapp/set2/sas/f/flrt3/FLRTVC-latest.zip')
              ::IO.copy_stream(download_expected, f)
              Log.log_debug('downloaded /tmp/FLRTVC-latest.zip')
            end
          end
          #
          command = '/bin/which unzip'
          returned = Utils.execute(command)
          if returned != 0
            Log.log_debug('downloaded /tmp/FLRTVC-latest.zip')
            # missing unzip on system
            # download and install
            unless ::File.exist?('/tmp/unzip-6.0-3.aix6.1.ppc.rpm')
              Log.log_debug('/tmp/unzip-6.0-3.aix6.1.ppc.rpm does not exist')
              ::File.open('/tmp/unzip-6.0-3.aix6.1.ppc.rpm', 'w') do |f|
                download_expected = open('https://public.dhe.ibm.com/aix/freeSoftware/aixtoolbox/RPMS/ppc/unzip/unzip-6.0-3.aix6.1.ppc.rpm')
                ::IO.copy_stream(download_expected, f)
                Log.log_debug('downloaded /tmp/unzip-6.0-3.aix6.1.ppc.rpm')
              end

              command = '/bin/rpm -i /tmp/unzip-6.0-3.aix6.1.ppc.rpm'
              Log.log_debug('launching command ' + command)
              returned = Utils.execute(command)
              Log.log_debug('command ' + command + ' returns ' + returned.to_s)
              if returned == 0
                Log.log_debug('installed unzip-6.0-3.aix6.1.ppc.rpm')
              end
            end
          end
          #
          if returned == 0
            command = '/bin/unzip -o /tmp/FLRTVC-latest.zip -d /usr/bin'
            Log.log_debug('launching command ' + command)
            returned = Utils.execute(command)
            Log.log_debug('command ' + command + ' returns ' + returned.to_s)
            if returned == 0
              Log.log_debug('installed /usr/bin/flrtvc.ksh')
            end
          end
          #
          if returned == 0
            # set execution mode
            File.new('/usr/bin/flrtvc.ksh').chmod(0755)
            Log.log_debug('set execution mode on /usr/bin/flrtvc.ksh')
          end
        end
        Log.log_debug('Finish check_install_flrtvc')
        returned
      end

      # ########################################################################
      # name : status
      # param : in:target:string
      # return : hash containing oslevel and lslpp -e
      # description : status a target
      # ########################################################################
      def self.status(target)
        Log.log_debug('Into status for ' + target)
        #
        status_output = {}
        remote_cmd1 = '/bin/oslevel -s'
        remote_output1 = []
        remote_cmd_rc1 = Remote.c_rsh(target, remote_cmd1, remote_output1)
        if remote_cmd_rc1 == 0
          status_output['oslevel -s'] = remote_output1[0].chomp
        end
        #
        remote_cmd2 = "/bin/lslpp -e | /bin/sed '/STATE codes/,$ d'"
        remote_output2 = []
        remote_cmd_rc2 = Remote.c_rsh(target, remote_cmd2, remote_output2)
        if remote_cmd_rc2 == 0
          status_output['lslpp -e'] = remote_output2[0].chomp
        end
        status_output
      end
    end # Utils
  end
end
