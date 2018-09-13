# ##############################################################################
# To define constants
# If run inside Puppet some constants come from Facter, otherwise they are
#  hard_coded.
# ##############################################################################
module Automation
  module Lib
    class Constants

      def self.debug_level
        hash = Facter.value(:props)
        hash['debug_level']
      rescue StandardError
        4
      end

      def self.inst_dir
        hash = Facter.value(:props)
        hash['inst_dir']
      rescue StandardError
        '/etc/puppetlabs/code/environments/production/modules'
      end

      def self.output_dir
        hash = Facter.value(:props)
        hash['output_dir']
      rescue StandardError
        '/etc/puppetlabs/code/environments/production/modules/aixautomation/output'
      end
    end # Constants
  end
end
