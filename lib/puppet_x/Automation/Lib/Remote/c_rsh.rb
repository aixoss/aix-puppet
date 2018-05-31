require_relative '../Log.rb'
require 'open3'

module Automation
  module Lib
    module Remote
      # ########################################################################
      # name : c_rsh
      # param : target   input array ["target", "oslevel -s"]
      # param : command  input
      # param : output[] output if status is ok, otherwise stderr
      # return : status execution of command on target
      # description : to encapsulate any command to be run on
      #   a target thru c_rsh
      # ########################################################################
      def self.c_rsh(target, command, output)
        Log.log_debug("target=#{target}")
        Log.log_debug("remote command=#{command}")
        c_rsh_command = '/usr/lpp/bos.sysmgt/nim/methods/c_rsh ' + target + \
' "' + command + '"'
        Log.log_debug("c_rsh command=#{c_rsh_command}")
        stdout, stderr, status = Open3.capture3(c_rsh_command.to_s)
        if Constants.debug_level >= FULL_DEBUG_LEVEL
          if !stdout.nil? && !stdout.strip.empty?
            Log.log_debug("c_rsh stdout=#{stdout}")
          end
        end
        if !stderr.nil? && !stderr.strip.empty?
          Log.log_err("c_rsh stderr=#{stderr}")
        end
        unless status.nil?
          Log.log_debug("c_rsh status=#{status}")
        end
        output[0] = if status
                      stdout
                    else
                      stderr
                    end
        status
      end
    end
  end
end
