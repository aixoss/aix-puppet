# ################################################################
#  To define constants
#  If run inside puppet some constants come from Facter, otherwise
#   they are hard_coded.
# ################################################################
module Automation
  module Lib
    class Constants
      def self.debug_level
        Facter.value(:debug_level)
      rescue StandardError
        4
      end
    end
  end
end
