require_relative '../Log.rb'
require 'open3'

module Automation
  module Lib
    # ##########################################################################
    #
    #
    #
    # ##########################################################################
    module Remote
      # ########################################################################
      # name : c_rsh
      # param : target   input array ["target", "oslevel -s"]
      # param : command  input
      # param : output[] output if status is ok, otherwise stderr
      # return : status execution of command on target
      # description : to encapsulate any command to be run on
      #   a target through c_rsh. Return code of the remote command is
      #   returned through C_RSH_CMD_RC parsing in output.
      # ########################################################################
      def self.c_rsh(target,
          command,
          output)
        Log.log_debug("target=#{target}, remote command=#{command}")
        #
        c_rsh_command = '/usr/lpp/bos.sysmgt/nim/methods/c_rsh ' + target +
            ' "' + command + '; echo C_RSH_CMD_RC=\$?"'
        c_rsh_rc = 99 # init value
        Log.log_debug("c_rsh command=#{c_rsh_command}")
        stdout2 = ''
        stdout, stderr, _status = Open3.capture3(c_rsh_command.to_s)
        stdout.each_line do |line|
          if line =~ /C_RSH_CMD_RC=([0-9]+)/
            c_rsh_rc = Regexp.last_match(1)
          else
            stdout2 += line
          end
        end
        c_rsh_rc = c_rsh_rc.to_i
        if Constants.debug_level >= FULL_DEBUG_LEVEL
          if !stdout.nil? && !stdout.strip.empty?
            Log.log_debug("c_rsh stdout=#{stdout}")
          end
          if !stdout2.nil? && !stdout2.strip.empty?
            Log.log_debug("c_rsh stdout2=#{stdout2}")
          end
        end
        if !stderr.nil? && !stderr.strip.empty?
          Log.log_err("c_rsh stderr=#{stderr}")
        end
        if c_rsh_rc == 0
          output[0] = stdout2
        elsif !stderr.nil? and !stderr.empty?
          output[0] = stderr
        else
          output[0] = stdout2
        end
        c_rsh_rc
      end


      # ########################################################################
      # name : c_rsh2
      # param : target   input array ["target", "oslevel -s"]
      # param : command  input
      # param : output[] output if status is ok, otherwise stderr
      # return : C_RSH_CMD_RC value returned by c_rsh command
      # description : to encapsulate any command to be run on
      #   a target through c_rsh. Return code of the remote command is
      #   returned through C_RSH_CMD_RC parsing in output.
      # ########################################################################
      def self.c_rsh2(target,
          command,
          output)
        Log.log_debug("c_rsh2 target=#{target}, remote command=#{command}")
        #
        c_rsh_command = '/usr/lpp/bos.sysmgt/nim/methods/c_rsh ' + target +
            ' "' + command + '; echo C_RSH_CMD_RC=\$?"'
        c_rsh_rc = 99 # init value
        Log.log_debug("c_rsh2 command=#{c_rsh_command}")
        stdout2 = ''
        stderr2 = ''
        exit_status = Open3.popen3({'LANG' => 'C'}, c_rsh_command) do |_stdin, stdout, stderr, wait_thr|
          thr = Thread.new do
            loop do
              print '.'
              sleep 3
            end
          end
          sleep 4
          stdout.each_line do |line|
            if line =~ /C_RSH_CMD_RC=([0-9]+)/
              c_rsh_rc = Regexp.last_match(1)
              Log.log_debug("c_rsh_rc=#{c_rsh_rc}")
            else
              stdout2 += line
            end
          end
          c_rsh_rc = c_rsh_rc.to_i
          if !stdout2.nil?
            Log.log_debug("c_rsh2 stdout2=#{stdout2}")
          end
          stderr.each_line do |line|
            Log.log_err("[STDERR]=#{line}")
            stderr2 += line
          end
          #
          if c_rsh_rc == 0
            output[0] = stdout2
          elsif !stderr2.nil?
            output[0] = stderr2
          else
            output[0] = stdout2
          end
          thr.exit
          # Process::Status object returned.
        end
        c_rsh_rc
      end
    end # Module Remote
  end
end
