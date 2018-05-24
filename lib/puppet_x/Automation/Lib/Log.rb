require 'logger'
require 'open3'
require 'pp'

module Automation
  module Lib
    ERROR_LEVEL = 1
    WARNING_LEVEL = 2
    INFO_LEVEL = 3
    DEBUG_LEVEL = 4
    LARGE_DEBUG_LEVEL = 5
    FULL_DEBUG_LEVEL = 6

    # ##########################################################################
    # name : LoggerSingleton class
    # description : wrapper of Logger with a singleton-design-pattern
    # ##########################################################################
    class LoggerSingleton
      # timestamp = Time.now.strftime('%Y-%m-%d_%H-%M-%S')
      # log_file_name = '/tmp/AixAutomation_' + timestamp.to_s + '.log'
      log_file_name = '/tmp/PuppetAixAutomation.log'
      @@instance = Logger.new(log_file_name, 12, 1_024_000)
      @@instance.datetime_format = '%Y-%m-%d %H:%M:%S'

      def self.instance
        @@instance
      end
    end

    # ##########################################################################
    # name : Log class
    # description : collection of log utility class methods
    # All these methods are made independent from Puppet framework thanks
    #  to rescue blocks
    # ##########################################################################
    class Log
      # ########################################################################
      # name : log_debug
      # param :input:message:string
      # return : none
      # description : to log in debug mode, displayed only with --debug
      #  rescue is here to be able to run code outside of Puppet
      # ########################################################################
      def self.log_debug(message)
        if Constants.debug_level >= FULL_DEBUG_LEVEL
          begin
            log_item = 'Stack Trace=' + caller.inspect
            Puppet.debug(log_item)
            LoggerSingleton.instance.debug {log_item}
          rescue StandardError
            p 'DEBUG Stack Trace=' + caller.inspect
          end
        end
        if Constants.debug_level >= DEBUG_LEVEL
          begin
            # This is displayed only with --debug
            Puppet.debug(message)
            LoggerSingleton.instance.debug {message}
          rescue StandardError
            p 'DEBUG ' + message
          end
        end
      end

      # ########################################################################
      # name : log_info
      # param :input:message:string
      # return : none
      # description : to log in info mode, displayed only with --debug
      #  rescue is here to be able to run code outside of Puppet
      # ########################################################################
      def self.log_info(message)
        if Constants.debug_level >= INFO_LEVEL
          begin
            # This is displayed only with --debug
            Puppet.info(message)
            LoggerSingleton.instance.info {message}
          rescue StandardError
            p 'INFO ' + message
          end
        end
      end

      # ########################################################################
      # name : log_warning
      # param :input:message:string
      # return : none
      # description : to log in warn mode, always displayed
      #  rescue is here to be able to run code outside of Puppet
      # ########################################################################
      def self.log_warning(message)
        # This is displayed even without --debug
        Puppet.warning(message)
        LoggerSingleton.instance.warning {message}
      rescue StandardError
        p 'WARNING ' + message
      end

      # ########################################################################
      # name : log_err
      # param :input:message:string
      # return : none
      # description : to log in error mode, always displayed
      #  rescue is here to be able to run code outside of Puppet
      # ########################################################################
      def self.log_err(message)
        begin
          # This is displayed even without --debug
          Puppet.err(message)
          LoggerSingleton.instance.error {message}
        rescue StandardError
          p 'ERROR ' + message
        end

        if Constants.debug_level >= FULL_DEBUG_LEVEL
          ###########################################################
          # To have execution stack of all threads into one file
          ###########################################################
          File.open("/tmp/AixAutomation_ruby_backtrace_#{Process.pid}.txt", 'a') do |f|
            f.puts "--- dump backtrace for all threads at #{Time.now}"
            if Thread.current.respond_to?(:backtrace)
              Thread.list.each do |t|
                f.puts t.inspect
                PP.pp(t.backtrace.delete_if {|frame| frame =~ /^#{File.expand_path(__FILE__)}/},
                      f) # remove frames resulting from calling this method
              end
            else
              PP.pp(caller.delete_if {|frame| frame =~ /^#{File.expand_path(__FILE__)}/},
                    f) # remove frames resulting from calling this method
            end
          end
        end
      end
    end
  end
end
