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
                 \"#{resource[:actions]}\" actions on \"#{resource[:vios_pairs]}\" targets with \"#{resource[:lpp_source]}\" lpp_source.")
    #
    # default value for returned, depends on 'ensure'
    returned = true
    returned = false if resource[:ensure] == 'absent'

    actions = resource[:actions]

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
    if actions.include? 'save'
      results = Vios.find_best_alt_disks(viospairs)
      Log.log_info('results=' + results.to_s)
      results.each do |vios_pairs|
        vios_pairs.each do |vios_pair|
          vios_pair.each do |vios|
            Log.log_info('vios=' + vios.to_s)
            if vios.length == 3
              Log.log_info('we can attempt a alt_disk_copy')
            end
            Log.log_info('Attempting a alt_disk_copy')
            ret = Vios.perform_alt_disk_install(vios[0], vios[1])
            Log.log_info('alt_disk_copy ret=' + ret.to_s)
            if ret == 0
              Log.log_info('Waiting for alt_disk_copy to be done')
              ret = Vios.wait_alt_disk_install(vios[0])
              Log.log_info('alt_disk_copy ret = ' + ret.to_s)
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

