require_relative '../puppet_x/Automation/Lib/Log.rb'
#
# # ##########################################################################
# # name : apply factor
# # param : none
# # return :
# # description : to display contents of manifests/init.pp being applied
# # ##########################################################################
include Automation::Lib
#
Facter.add('applied_manifest') do
  setcode do
    Log.log_info('Computing "applied_manifest" facter')
    applied_manifest = {}
    contents = ''
    init_pp_file = ::File.join('/etc/puppetlabs/code/environments/production/modules/aixautomation/manifests/init.pp')
    File.open(init_pp_file, 'r') do |init_pp_file_handler|
      Log.log_info('Contents of manifests/init.pp')
      while (line = init_pp_file_handler.gets)
        next unless !line.nil? && !line.strip.empty?
        contents += line unless line.to_s =~ /^#.*/
      end
      applied_manifest['manifest'] = contents
      init_pp_file_handler.close
    end
    applied_manifest
  end
end
