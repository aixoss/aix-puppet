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
    Log.log_info("Provider viosmngt 'exists?' method : we want to realize: \
                 \"#{resource[:ensure]}\" for \"#{resource[:actions]}\" actions \
on \"#{resource[:vios_pairs]}\" targets \
with \"#{resource[:vios_altinst_rootvg]}\" for vios_altinst_rootvg and \
with \"#{resource[:altinst_rootvg_force]}\" for altinst_rootvg_force and \
with \"#{resource[:vios_lpp_sources]}\" lpp_sources and
with \"#{resource[:update_options]}\" update_options.")
    #
    # default value for returned, depends on 'ensure'
    returned = true
    returned = false if resource[:ensure] == 'absent'

    actions = resource[:actions]
    Log.log_debug('actions=' + actions.to_s)
    #
    vios_disks = resource[:vios_altinst_rootvg]
    Log.log_debug('vios_disks=' + vios_disks.to_s)
    #
    force = resource[:altinst_rootvg_force].to_s
    Log.log_debug('force=' + force.to_s)
    #
    vios_pairs = resource[:vios_pairs]
    Log.log_debug('vios_pairs=' + vios_pairs.to_s)
    #
    vios_lppsources = resource[:vios_lpp_sources]
    Log.log_debug('vios_lppsources=' + vios_lppsources.to_s)
    #
    options = resource[:options]
    Log.log_debug('options=' + options.to_s)
    #
    update_options = resource[:update_options]
    Log.log_debug('update_options=' + update_options.to_s)

    facter_vios = {}
    facter_hmc = {}

    if actions.include? 'check' or actions.include? 'health'
      #
      Vios.check_vioshc
      facter_vios = Facter.value(:vios)
      Log.log_info('facter vios=' + facter_vios.to_s)
      #
      facter_hmc = Facter.value(:hmc)
      Log.log_info('facter hmc=' + facter_hmc.to_s)
    end

    # We loop against vios_pairs
    Log.log_info('We loop against vios_pairs=' + vios_pairs.to_s)
    vios_pairs.each do |vios_pair|
      Log.log_info('vios_pair=' + vios_pair.to_s)
      #
      if actions.include? 'check' or actions.include? 'health'
        #
        nim_vios = facter_vios
        hmc_id = ''
        hmc_ip = ''
        #
        if actions.include? 'health'
          vios_pair.each do |vios|
            Log.log_info('vios=' + vios)
            hmc_id = nim_vios[vios]['mgmt_hmc_id']
            hmc_ip = facter_hmc[hmc_id]['ip']
            # Do it only once per pair
            break
          end
          #
          if vios_pair.size == 2 or vios_pair.size == 1
            Log.log_info('nim_vios 1 =' + nim_vios.to_s + ' hmc_id=' + hmc_id + ' hmc_ip=' + hmc_ip)
            ret = Vios.vios_health_init(nim_vios,
                                        hmc_id,
                                        hmc_ip)
            if ret == 0
              Log.log_info('nim_vios 2 =' + nim_vios.to_s)
              ret = Vios.vios_health_check(nim_vios,
                                           hmc_ip,
                                           vios_pair)
              if ret == 1
                Log.log_err('Check health of "' + vios_pair.to_s + '" vios pair is unsuccessful')
                # This does not prevent from continuing on another pair
                next
              end
            else
              Log.log_warning('Not possible to check health of vios_pair : ' + vios_pair.to_s + ' as init step failed.')
              # This does not prevent from continuing on another pair
              next
            end
          else
            Log.log_warning('Not possible to check health of vios_pair : ' + vios_pair.to_s + ' as neither one nor two members into pair.')
            # This does not prevent from continuing on another pair
            next
          end
        end

        #
        Log.log_debug('Checking SSP cluster on : ' + vios_pair.to_s + ' vios pair')
        cluster_name = Vios.check_ssp_cluster(vios_pair,
                                              nim_vios)
        #
        if !cluster_name.empty?
          #
          Log.log_debug('Checking SSP cluster on : ' + vios_pair.to_s + ' vios pair')
          returned = Vios.get_vios_ssp_status(vios_pair,
                                              nim_vios)
          # Log.log_debug('After getting SSP status : ' + nim_vios.to_s + ' returned=' + returned.to_s)
          ssp_check = false
          if returned == 0
            ssp_check = Vios.check_vios_ssp_status(vios_pair,
                                                   nim_vios)
            Log.log_debug('After checking SSP status : ssp_check=' + ssp_check.to_s)
          end
          Log.log_warning('SSP status KO on : ' + vios_pair.to_s + ' vios pair') unless ssp_check
          unless ssp_check
            # This does not prevent from continuing on another pair
            next
          end

          # Only for quick testing
          # vios_pair.each do |vios|
          #   Log.log_info('vios=' + vios.to_s)
          #   ssp_check = Vios.ssp_stop_start('stop',
          #                                   vios,
          #                                   vios_pair,
          #                                   nim_vios)
          #   Log.log_info('ssp_stop_start stop returning ' + ssp_check.to_s)
          #
          #   ssp_check = Vios.ssp_stop_start('start',
          #                                   vios,
          #                                   vios_pair,
          #                                   nim_vios)
          #   Log.log_info('ssp_stop_start stop returning ' + ssp_check.to_s)
          # end


        else
          Log.log_debug('No need to check SSP cluster on : ' + vios_pair.to_s + ' vios pair')
        end
      end

      #
      if actions.include? 'save'
        #
        vios_mirrors = {}
        hvios = Vios.check_altinst_rootvg_pair(vios_pair)
        if force == 'no'
          unless hvios["1"].empty?
            Log.log_warning('Because these "' + hvios["1"].to_s + '" vios already have an "altinst_rootvg", you should use "vios_force=yes" or "vios_force=reuse"')
            # This does not prevent from continuing on another pair
            next
          end
        end

        # A priori, vios_pair is kept
        #  It won't be kept, if ever the check_rootvg_mirror test fails.
        b_vios_pair_kept = 1
        vios_pair.each do |vios|
          Log.log_info('vios=' + vios.to_s)
          #
          if !vios_lppsources.nil?
            value_lpp_source = vios_lppsources[vios]
            if value_lpp_source.nil? or value_lpp_source.empty?
              msg = 'No vios_lpp_sources set on this "' + vios.to_s + '" vios. No update to be done. Therefore no need to perform "save"'
              Vios.add_vios_msg(vios, msg)
              Log.log_info(msg)
              # This does not prevent us from continuing on next vios
              next
            end
          else
            msg = 'No vios_lpp_sources set. No update to be done. Therefore no need to perform "save"'
            Vios.add_vios_msg(vios, msg)
            Log.log_info(msg)
            # This does not prevent us from continuing on next vios
            next
          end


          # If vios already has an altinst_rootvg and we have force="reuse"
          #  then there is no need:
          #   - to check for mirror
          #   - to find best alt disk
          #   - to mirror
          skip_unmirror_find_mirror = false
          if force == 'reuse' and hvios["1"].include? vios
            msg = 'No need to check mirroring on "' + vios.to_s + '" vios, as we reuse altinst_rootvg'
            Vios.add_vios_msg(vios, msg)
            Log.log_info(msg)
            skip_unmirror_find_mirror = true
          end

          #
          unless skip_unmirror_find_mirror
            copies = []
            nb_of_physical_partitions = []
            ret = Vios.check_rootvg_mirror(vios, copies, nb_of_physical_partitions)
            Log.log_info('check_rootvg_mirror=' + vios.to_s +
                             ' ret=' + ret.to_s +
                             ' copies=' + copies.to_s +
                             ' nb_of_physical_partitions=' + nb_of_physical_partitions.to_s)
            #
            if ret == -1
              b_vios_pair_kept = 0
            else
              # ret == 0 : no mirror, or ret == 1 mirror ok
              # keep somewhere all information about mirroring
              #  when mirroring exists on a rootvg of a vios
              vios_mirrors[vios] = copies[0]
              Log.log_debug('vios_mirrors=' + vios_mirrors.to_s)
              Log.log_debug('vios_mirrors[vios]=' + vios_mirrors[vios].to_s)
            end
            #
            if b_vios_pair_kept == 0
              # This does not prevent from continuing on another pair
              next
            end
            chosen_disk = ''
            unless vios_disks.nil?
              # disk may have been chosen by user
              chosen_disk = vios_disks[vios]
            end

            #
            vios_best_disk = Vios.find_best_alt_disk_vios(vios,
                                                          hvios,
                                                          chosen_disk,
                                                          nb_of_physical_partitions[0],
                                                          force)
            # The 'vios_best_disk' output contains for vios the disk on which to perform alt_disk_copy.
            Log.log_info('vios_best_disk=' + vios_best_disk.to_s)
            #
            ret = Vios.unmirror_altcopy_mirror_vios(vios_best_disk,
                                                    vios_mirrors)
            if ret != 0
              Log.log_warning('Because vios unmirror_altcopy_mirror returns ' + ret.to_s + ' on "' + vios_best_disk.to_s + '", update cannot be run.')
              # This does not prevent us from continuing on next pair
              next
            end
          end
        end
      end

      #
      if actions.include? 'update'
        # VIOS update: at least!
        vios_pair.each do |vios|
          #
          value_lpp_source = vios_lppsources[vios]
          if value_lpp_source.nil? or value_lpp_source.empty?
            Log.log_info('No lpp_source set on this "' + vios.to_s + '" vios. No update to be done.')
            next
          elsif Vios.check_altinst_rootvg_vios(vios) == 1 # Check altinst_rootvg

            if actions.include? 'autocommit' and !options.include? 'preview'
              # Commit applied lpps if asked, does not perform autocommit if preview mode
              Log.log_info('Perform autocommit before NIM updateios for "' + vios.to_s + '" vios')
              autocommit_output_file = Vios.get_updateios_output_file_name(vios, 'autocommit')
              autocommit_cmd = '/usr/sbin/nim -o updateios -a updateios_flags=-commit -a filesets=all ' +
                  vios.to_s + ' >' + autocommit_output_file + ' 2>&1'
              # Perform autocommit
              step = 'autocommit'
              autocommit_ret = Vios.nim_updateios(autocommit_cmd, vios, step)
              if autocommit_ret == 0
                Log.log_info('vios autocommit of "' + vios.to_s + '" vios returns ' + autocommit_ret.to_s)
              else
                Log.log_err('vios autocommit of "' + vios.to_s + '" vios returns ' + autocommit_ret.to_s)
              end
            end

            #
            ssp_start_stop_ret = Vios.ssp_stop_start('stop',
                                                     vios,
                                                     vios_pair,
                                                     nim_vios)
            if ssp_start_stop_ret
              Log.log_info('SSP cluster stop returns ' + ssp_start_stop_ret.to_s)
            else
              Log.log_err('SSP cluster stop returns ' + ssp_start_stop_ret.to_s)
            end

            # Prepare update command
            Log.log_info('Launching update of "' + vios.to_s + '" vios with "' + value_lpp_source.to_s + '" lpp_source.')
            update_cmd = Vios.prepare_updateios_command(vios,
                                                        value_lpp_source,
                                                        options,
                                                        update_options)
            # Perform update
            step = 'update'
            update_ret = Vios.nim_updateios(update_cmd, vios, step)
            if update_ret == 0
              Log.log_info('vios update of "' + vios.to_s + '" vios returns ' + update_ret.to_s)
            else
              Log.log_err('vios update of "' + vios.to_s + '" vios returns ' + update_ret.to_s)
            end

            #
            ssp_start_stop_ret = Vios.ssp_stop_start('start',
                                                     vios,
                                                     vios_pair,
                                                     nim_vios)
            if ssp_start_stop_ret
              Log.log_info('SSP cluster start returns ' + ssp_start_stop_ret.to_s)
            else
              Log.log_err('SSP cluster start returns ' + ssp_start_stop_ret.to_s)
            end
          else
            Log.log_warning('Because there is no altinst_rootvg on "' + vios.to_s + '" vios, update cannot be run.')
          end
        end
      end
    end

    #
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