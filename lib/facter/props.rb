require_relative '../puppet_x/Automation/Lib/Constants.rb'
require_relative '../puppet_x/Automation/Lib/Log.rb'

# ##########################################################################
# name : props factor
# param : none
# return : configuration  properties
# description : to share configuration properties
# ##########################################################################
include Automation::Lib

Facter.add('props') do
  setcode do
    props = {}
    Log.log_info('Setting "conf properties" facter')
    props['debug_level'] = 4
    props['inst_dir'] = '/etc/puppetlabs/code/environments/production/modules'
    props['output_dir'] = '/etc/puppetlabs/code/environments/production/modules/aixautomation/output'
    props
  end
end
