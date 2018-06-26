require_relative '../puppet_x/Automation/Lib/Log.rb'
require_relative '../puppet_x/Automation/Lib/Suma.rb'

# ##########################################################################
# name : servicepacks factor
# param : none
# return : hash of servicepacks per technical level
# description : this factor builds a fact called 'servicepacks' containing
#  a hash with all technical levels as keys and services packs as values.
# ##########################################################################
include Automation::Lib

Facter.add('servicepacks') do
  setcode do
    Log.log_info('Computing "servicepacks" facter')
    Suma.sp_per_tl
  end
end
