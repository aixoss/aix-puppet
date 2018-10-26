require_relative '../puppet_x/Automation/Lib/Log.rb'
require_relative '../puppet_x/Automation/Lib/Suma.rb'
#
# ##############################################################################
# name : 'servicepacks' factor
# param : none
# return : hash of servicepacks per technical level
# description : this facter builds a fact called 'servicepacks' containing
#  a hash with all technical levels as keys and services packs as values.
# ##############################################################################
include Automation::Lib
#
Facter.add('servicepacks') do
  setcode do
    Log.log_info('Computing "servicepacks" facter')
    # Retrieves from :applied_manifest facter if download declaration is used
    applied_manifest = Facter.value(:applied_manifest)
    download = applied_manifest['download']
    if !download.nil? and download == true
      Suma.sp_per_tl
    else
      Log.log_info('Not necessary to compute "servicepacks" facter')
    end
  end
end
