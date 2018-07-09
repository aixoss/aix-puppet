require_relative '../puppet_x/Automation/Lib/Log.rb'
#
# ##############################################################################
# name : 'applied_manifest' factor
# param : none
# return : the applied manifest is returned : contents of manifests/init.pp
# description : this facter to display contents of manifests/init.pp being
#  applied, please note that commented lines are not displayed. Set of targets
#  used in manifests/init.pp is computed, this is used to restrict work being
#  done by 'standalones' facter to the sole list of targets being really used.
# ##############################################################################
#
Facter.add('applied_manifest') do
  setcode do
    Log.log_info('Computing "applied_manifest" facter')
    applied_manifest = {}
    contents = ''
    init_pp_file = ::File.join('/etc/puppetlabs/code/environments/production/modules/aixautomation/manifests/init.pp')
    File.open(init_pp_file, 'r') do |init_pp_file_handler|
      Log.log_info('Contents of manifests/init.pp')
      alltargets = []
      while (line = init_pp_file_handler.gets)
        next unless !line.nil? && !line.strip.empty?
        next if line.to_s =~ /^\s*#.*/
        contents += line
        line.to_s =~ /\s*targets\s*=>\s*"(.+?)",/
        targets_caught = Regexp.last_match(1)
        if !targets_caught.nil?
          targets = targets_caught.split(/[\s,']/)
          alltargets += targets
        end
      end
      applied_manifest['manifest'] = contents
      applied_manifest['targets'] = alltargets.uniq
      init_pp_file_handler.close
    end
    applied_manifest
  end
end
