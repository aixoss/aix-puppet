require_relative '../../../puppet_x/Automation/Lib/Vios.rb'
require_relative '../../../puppet_x/Automation/Lib/Log.rb'

# ##############################################################################
# name : 'viosmngt' provider of the 'vios' custom-type.
# description :
#   implement check/save/update/restore of VIOS above nim commands
# ##############################################################################
Puppet::Type.type(:vios).provide(:viosmngt) do
  include Automation::Lib

  commands :nim => '/usr/sbin/nim'

  # ###########################################################################
  # exists?
  #      Method      Ensure 	 Action	                  Ensure state
  #       result      value                              transition
  #      =======     =======   =======================  ================
  #      true        present   manage other properties  n/a
  #      false       present   create method            absent → present
  #      true        absent    destroy method           present → absent
  #      false       absent    do nothing               n/a
  # ###########################################################################
  def exists?
    Log.log_info("Provider viosmngt 'exists?' method : we want to realize: \"#{resource[:ensure]}\" for \
                 \"#{resource[:actions]}\" actions on \"#{resource[:vios_pairs]}\" targets with force=\"#{resource[:force]}\" \
with \"#{resource[:vios_lpp_sources]}\" lpp_source.")
    #
    # default value for returned, depends on 'ensure'
    returned = true
    returned = false if resource[:ensure] == 'absent'

    actions = resource[:actions]
    force = resource[:force].to_s

    #
    viospairs = resource[:vios_pairs]
    Log.log_info('viospairs=' + viospairs.to_s)

    if actions.include? 'check'
      #
      Vios.check_vioshc
      #
      facter_vios = Facter.value(:vios)
      Log.log_info('facter vios=' + facter_vios.to_s)
      #
      facter_hmc = Facter.value(:hmc)
      Log.log_info('facter hmc=' + facter_hmc.to_s)
      #
      nim_vios = facter_vios
      hmc_id = ''
      hmc_ip = ''
      #
      viospairs.each do |viospair|
        Log.log_info('viospair=' + viospair.to_s)
        viospair.each do |viosunit|
          Log.log_info('viosunit=' + viosunit)
          hmc_id = nim_vios[viosunit]['mgmt_hmc_id']
          hmc_ip = facter_hmc[hmc_id]['ip']
          break
        end
        #
        Log.log_info('nim_vios 1 =' + nim_vios.to_s + ' hmc_id=' + hmc_id + ' hmc_ip=' + hmc_ip)
        ret = Vios.vios_health_init(nim_vios,
                                    hmc_id,
                                    hmc_ip)
        if ret == 0
          Log.log_info('nim_vios 2 =' + nim_vios.to_s)
          Vios.vios_health_check(nim_vios,
                                 hmc_ip,
                                 viospair)
        else
          Log.log_err('not possible to check health of viospair : ' + viospair.to_s)
        end
      end
    end

    #
    vios_mirrors = {}
    if actions.include? 'save'
      #
      viospairs_kept = []
      viospairs.each do |viospair|
        # A priori, viospair is kept
        #  It won't be kept, if ever the check_rootvg_mirror test fails.
        b_viospair_kept = 1
        viospair.each do |vios|
          Log.log_info('vios=' + vios.to_s)
          copies = []
          ret = Vios.check_rootvg_mirror(vios, copies)
          Log.log_info('check_rootvg_mirror=' + vios.to_s + ' ret=' + ret.to_s + ' copies=' + copies.to_s)
          if ret != 0
            b_viospair_kept = 0
            break
          else
            # keep somewhere all information about mirroring
            #  when mirroring exists on a rootvg of a vios
            vios_mirrors[vios] = copies[0]
            Log.log_debug('vios_mirrors=' + vios_mirrors.to_s)
            Log.log_debug('vios_mirrors[vios]=' + vios_mirrors[vios].to_s)
          end
        end
        if b_viospair_kept == 1
          viospairs_kept.push(viospair)
        end
      end

      results = Vios.find_best_alt_disks(viospairs_kept, force)
      # The 'results' output contains more than vios_pairs with vios inside
      # It contains as well for each vios the disk on which
      #  to perform alt_disk_copy.
      Log.log_info('results=' + results.to_s)

      # Loop against results
      results.each do |vios_pairs|
        # Loop against pairs
        vios_pairs.each do |vios_pair|
          # Lpp against each pair
          vios_pair.each do |vios_disk|
            #
            Log.log_info('vios_disk=' + vios_disk.to_s)
            # As already said, there must be 2 elements into vios_disk array :
            #  first element is vios name
            #  second element is best disk to use to perform alt_disk_copy
            if vios_disk.length > 1
              Log.log_info('We can attempt an alt_disk_copy on ' + vios_disk.to_s)
              Log.log_debug('vios_mirrors=' + vios_mirrors.to_s)
              Log.log_debug('vios_mirrors[vios_disk[0]]=' + vios_mirrors[vios_disk[0]].to_s)
              Log.log_debug('!vios_mirrors[vios_disk[0]].nil?=' + (!vios_mirrors[vios_disk[0]].nil?).to_s)
              unless vios_mirrors[vios_disk[0]].nil?
                Log.log_debug('vios_mirrors[vios_disk[0]].length=' + (vios_mirrors[vios_disk[0]].length).to_s)
                if vios_mirrors[vios_disk[0]].length > 0
                  # If mirroring is active on the rootvg of this vios
                  #  unmirroring needs to be done here
                  # Vios.perform_unmirror(vios)
                  # If unmirroring has been correctly done, we can go on
                  #  otherwise we must give up
                  Log.log_info('The rootvg of this vios is mirrored')
                  Log.log_info('Attempting now to perform unmirror of rootvg on ' + vios_disk.to_s)
                  ret = Vios.perform_unmirror(vios_disk[0], 'rootvg')
                  Log.log_info('Perform unmirror returns ' + ret.to_s)
                else
                  # No need to unmirror
                end
              end

              Log.log_info('Attempting now an alt_disk_copy on ' + vios_disk.to_s)
              ret = Vios.perform_alt_disk_install(vios_disk[0], vios_disk[1])
              Log.log_info('Perform alt_disk_copy returns returns ' + ret.to_s)
              if ret == 0
                Log.log_info('Waiting for alt_disk_copy to be done')
                ret = Vios.wait_alt_disk_install(vios_disk[0])
                Log.log_info('Perform wait_alt_disk_copy returns returns ' + ret.to_s)
                if ret == -1
                  msg = "Manual intervention is required to verify the NIM alt_disk_install operation for #{vios_disk} being done!"
                  Log.log_err(msg)
                else
                  Log.log_debug('vios_mirrors=' + vios_mirrors.to_s)
                  Log.log_debug('vios_mirrors[vios_disk[0]]=' + vios_mirrors[vios_disk[0]].to_s)
                  Log.log_debug('!vios_mirrors[vios_disk[0]].nil?=' + (!vios_mirrors[vios_disk[0]].nil?).to_s)
                  unless vios_mirrors[vios_disk[0]].nil?
                    Log.log_info('Performing now back again mirroring of rootvg on ' + vios_disk.to_s)
                    Log.log_debug('vios_mirrors[vios_disk[0]].length=' + (vios_mirrors[vios_disk[0]].length).to_s)
                    if vios_mirrors[vios_disk[0]].length > 0
                      # if mirroring was active on the rootvg of this vios
                      #   and if unmirroring has been done
                      #  then we need to mirror again this rootvg
                      disk_copies = []
                      disk_copies.push(vios_mirrors[vios_disk[0]][2])
                      if vios_mirrors[vios_disk[0]].length > 2
                        disk_copies.push(vios_mirrors[vios_disk[0]][3])
                      end
                      Log.log_info('Attempting now to perform mirror of rootvg on ' + vios_disk.to_s)
                      Log.log_debug('disk_copies=' + disk_copies.to_s)
                      ret = Vios.perform_mirror(vios_disk[0],
                                                'rootvg',
                                                disk_copies)
                      Log.log_info('Perform mirror returns ' + ret.to_s)
                      Log.log_info('The rootvg of this vios was mirrored')
                    else
                      # No need to mirror as we did nt unmirror
                    end
                  end
                end
              else
                # Alt_disk_copy failed
              end
            else
              # We cannot do alt_disk_copy as we only have one parameter
              Log.log_info('We cannot attempt a alt_disk_copy on ' + vios.to_s)
            end
            break
          end
        end
      end
    end

    Log.log_info('Provider viosmngt "exists!" method returning ' + returned.to_s)
    returned
  end

  # ###########################################################################
  #
  #
  # ###########################################################################
  def create
    Log.log_info("Provider viosmngt 'create' method : doing : \"#{resource[:ensure]}\" for \"#{resource[:actions]}\" \
action on \"#{resource[:vios_pairs]}\" targets with \"#{resource[:vios_lpp_sources]}\" lpp_source.")
    #
    Log.log_debug('End of viosmngt.create')
  end

  # ###########################################################################
  #
  #
  # ###########################################################################
  def destroy
    Log.log_info("Provider viosmngt 'destroy' method : doing : \"#{resource[:ensure]}\" \
for \"#{resource[:actions]}\" action on \"#{resource[:vios_pairs]}\" \
targets with \"#{resource[:vios_lpp_sources]}\" lpp_source.")
    #
    Log.log_debug('End of viosmngt.destroy')
  end
end