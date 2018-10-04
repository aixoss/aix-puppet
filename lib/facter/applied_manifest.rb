require_relative '../puppet_x/Automation/Lib/Log.rb'
#
# ##############################################################################
# name : 'applied_manifest' factor
# param : none
# return : the applied manifest is returned : contents of manifests/init.pp
#  the list of targets used in manifests/init.pp is returned as well.
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
      allvios = []
      while (line = init_pp_file_handler.gets)
        next unless !line.nil? && !line.strip.empty?
        next if line.to_s =~ /^\s*#.*/
        contents += line
        line.to_s =~ /\s*targets\s*=>\s*"(.+?)",/
        targets_caught = Regexp.last_match(1)
        unless targets_caught.nil?
          targets = targets_caught.split(/[\s,']/)
          alltargets += targets
        end
        #
        line.to_s =~ /\s*(vios_pairs\s*=>\s*')(.+)'\s*/
        vios_pairs_caught = Regexp.last_match(2)
        if !vios_pairs_caught.nil? and !vios_pairs_caught.empty?
          Log.log_info('vios_pairs_caught=' + vios_pairs_caught.class.to_s + ' ' + vios_pairs_caught.to_s)
          vios_pairs_caught2 = vios_pairs_caught.scan(/\([\w\-]+,*[\w\-]*\)/)
          if !vios_pairs_caught2.nil? and !vios_pairs_caught2.empty?
            Log.log_info('vios_pairs_caught2=' + vios_pairs_caught2.class.to_s + ' ' + vios_pairs_caught2.to_s)
            vios_pairs_caught2.each do |vios_pair_caught2|
              Log.log_info('vios_pair_caught2=' + vios_pair_caught2.class.to_s + ' ' + vios_pair_caught2.to_s)
              vios_pair_caught2 =~ /\(([\w\-]+),*([\w\-]*)\)/
              if !vios_pair_caught2.nil? and !vios_pair_caught2.empty?
                vios1 = Regexp.last_match(1)
                allvios.push(vios1)
                Log.log_info('vios1=' + vios1.to_s)
                vios2 = Regexp.last_match(2)
                if !vios2.nil? and !vios2.empty?
                  allvios.push(vios2)
                  Log.log_info('vios2=' + vios2.to_s)
                end
              end
            end
          end
        end
      end
      applied_manifest['manifest'] = contents
      applied_manifest['targets'] = alltargets.uniq
      applied_manifest['vios'] = allvios.uniq
      init_pp_file_handler.close
    end
    applied_manifest
  end
end
