# ##############################################################################
# name : 'props' factor
# param : none
# return : configuration  properties
# description : to share configuration properties
# ##############################################################################
Facter.add('props') do
  setcode do
    props = {}
    props['debug_level'] = 4
    props['inst_dir'] = '/etc/puppetlabs/code/environments/production/modules'
    props['output_dir'] = '/etc/puppetlabs/code/environments/production/modules/aixautomation/output'
    props
  end
end
