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
with \"#{resource[:lpp_source]}\" lpp_source.")
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
      Log.log_info('results=' + results.to_s)
      results.each do |vios_pairs|
        vios_pairs.each do |vios_pair|
          #
          vios_pair.each do |vios|
            #
            Log.log_info('vios=' + vios.to_s)
            # There must be 2 elements into vios array :
            #  first element is vios name
            #  second element is best disk to use to perform alt_disk_copy
            if vios.length > 1
              Log.log_info('We can attempt an alt_disk_copy on ' + vios.to_s)
              Log.log_debug('vios_mirrors=' + vios_mirrors.to_s)
              Log.log_debug('vios_mirrors[vios[0]]=' + vios_mirrors[vios[0]].to_s)
              Log.log_debug('!vios_mirrors[vios[0]].nil?=' + (!vios_mirrors[vios[0]].nil?).to_s)
              unless vios_mirrors[vios[0]].nil?
                Log.log_debug('vios_mirrors[vios[0]].length=' + (vios_mirrors[vios[0]].length).to_s)
                if vios_mirrors[vios[0]].length > 0
                  # if mirroring is active on the rootvg of this vios
                  #  unmirroring needs to be done here
                  # Vios.perform_unmirror(vios)
                  # if unmirroring has been corretly done we can go one
                  #  otherwise we must give up
                  Log.log_info('The rootvg of this vios is mirrored')
                  ret = Vios.perform_unmirror(vios[0], 'rootvg')
                  Log.log_info('unmirror ret=' + ret.to_s)
                end
              end
              Log.log_info('Attempting an alt_disk_copy on ' + vios.to_s)
            ret = Vios.perform_alt_disk_install(vios[0], vios[1])
            Log.log_info('alt_disk_copy ret=' + ret.to_s)
            if ret == 0
              Log.log_info('Waiting for alt_disk_copy to be done')
              ret = Vios.wait_alt_disk_install(vios[0])
              if ret == -1
                msg = "Manual intervention is required to verify the NIM alt_disk_install operation for #{vios} being done!"
                Log.log_err(msg)
              else
                Log.log_debug('vios_mirrors=' + vios_mirrors.to_s)
                Log.log_debug('vios_mirrors[vios[0]]=' + vios_mirrors[vios[0]].to_s)
                Log.log_debug('!vios_mirrors[vios[0]].nil?=' + (!vios_mirrors[vios[0]].nil?).to_s)
                unless vios_mirrors[vios[0]].nil?
                  Log.log_info('Performing back again mirroring of rootvg')
                  Log.log_debug('vios_mirrors[vios[0]].length=' + (vios_mirrors[vios[0]].length).to_s)
                  if vios_mirrors[vios[0]].length > 1
                    # if mirroring was active on the rootvg of this vios
                    #   and if unmirroring has been done
                    #  then we need to mirror again this rootvg
                    disk_copies = []
                    disk_copies.push(vios_mirrors[vios[0]][2])
                    if vios_mirrors[vios[0]].length > 2
                      disk_copies.push(vios_mirrors[vios[0]][3])
                    end
                    Log.log_debug('disk_copies=' + disk_copies.to_s)
                    Vios.perform_mirror(vios[0],
                                        'rootvg',
                                        disk_copies)
                    Log.log_info('The rootvg of this vios was mirrored')
                  end
                end
              end
              Log.log_info('alt_disk_copy ret = ' + ret.to_s)
            end
            else
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
action on \"#{resource[:vios_pairs]}\" targets with \"#{resource[:lpp_source]}\" lpp_source.")
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
targets with \"#{resource[:lpp_source]}\" lpp_source.")
    #
    Log.log_debug('End of viosmngt.destroy')
  end

end

