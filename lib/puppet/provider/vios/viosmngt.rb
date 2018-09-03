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
                 \"#{resource[:actions]}\" actions on \"#{resource[:vios_pairs]}\" targets with force=\"#{resource[:altinst_rootvg_force]}\" \
with \"#{resource[:vios_lpp_sources]}\" lpp_source.")
    #
    # default value for returned, depends on 'ensure'
    returned = true
    returned = false if resource[:ensure] == 'absent'

    actions = resource[:actions]
    force = resource[:altinst_rootvg_force].to_s

    #
    vios_pairs = resource[:vios_pairs]
    Log.log_info('vios_pairs=' + vios_pairs.to_s)

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
      if actions.include? 'health'
        vios_pairs.each do |vios_pair|
          Log.log_info('vios_pair=' + vios_pair.to_s)
          vios_pair.each do |viosunit|
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
                                   vios_pair)
          else
            Log.log_err('not possible to check health of vios_pair : ' + vios_pair.to_s)
          end
        end
      end
    end

    #
    vios_mirrors = {}
    if actions.include? 'save'
      #
      vios_pairs_kept = []
      vios_pairs.each do |vios_pair|
        # A priori, vios_pair is kept
        #  It won't be kept, if ever the check_rootvg_mirror test fails.
        b_vios_pair_kept = 1
        vios_pair.each do |vios|
          Log.log_info('vios=' + vios.to_s)
          copies = []
          ret = Vios.check_rootvg_mirror(vios, copies)
          Log.log_info('check_rootvg_mirror=' + vios.to_s + ' ret=' + ret.to_s + ' copies=' + copies.to_s)
          if ret == -1
            b_vios_pair_kept = 0
            break
          else
            # ret == 0 : no mirror, or ret == 1 mirror ok
            # keep somewhere all information about mirroring
            #  when mirroring exists on a rootvg of a vios
            vios_mirrors[vios] = copies[0]
            Log.log_debug('vios_mirrors=' + vios_mirrors.to_s)
            Log.log_debug('vios_mirrors[vios]=' + vios_mirrors[vios].to_s)
          end
        end
        #
        if b_vios_pair_kept == 1
          vios_pairs_kept.push(vios_pair)
        end
      end

      hvios = Vios.check_altinst_rootvg(vios_pairs_kept)
      if force == 'no'
        unless hvios["1"].empty?
          Log.log_warning('As these "' + hvios["1"].to_s + '" vios already have an "altinst_rootvg", you should use "vios_force=yes" or "vios_force=reuse"')
          return
        end
      end

      vios_pairs_best_disks = Vios.find_best_alt_disks(vios_pairs_kept, hvios, force)
      # The 'vios_pairs_best_disks' output contains more than vios_pairs with vios inside
      # It contains as well for each vios the disk on which to perform alt_disk_copy.
      Log.log_info('vios_pairs_best_disks=' + vios_pairs_best_disks.to_s)


      Vios.unmirror_altcopy_mirror(vios_pairs_best_disks, vios_mirrors)


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