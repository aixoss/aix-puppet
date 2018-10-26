require_relative '../../../puppet_x/Automation/Lib/Nim.rb'
require_relative '../../../puppet_x/Automation/Lib/Utils.rb'
require_relative '../../../puppet_x/Automation/Lib/Log.rb'

# ##############################################################################
# name : 'nimpush' provider of the 'patchmngt' custom-type.
# description :
#   implement install/update of LPARs above nim commands
# ##############################################################################

Puppet::Type.type(:patchmngt).provide(:nimpush) do
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
    Log.log_info("Provider nimpush 'exists?' method : we want to realize : \"#{resource[:ensure]}\" for \
\"#{resource[:action]}\" action sync=\"#{resource[:sync]}\" mode=\"#{resource[:mode]}\" \
on \"#{resource[:targets]}\" targets with \"#{resource[:lpp_source]}\" lpp_source.")

    # default value for returned, depends on 'ensure'
    returned = true
    returned = false if resource[:ensure] == 'absent'

    #
    targets = resource[:targets].to_s
    Log.log_debug('targets=' + targets)
    @targets_to_apply = []
    Log.log_debug('targets_to_apply=' + @targets_to_apply.to_s)
    targets_array = targets.split(' ')
    Log.log_debug('targets_array=' + targets_array.to_s)
    #
    lpp_source = resource[:lpp_source].to_s
    action = resource[:action].to_s
    mode = resource[:mode].to_s

    case action.to_s
    when 'install', 'update'
      case mode.to_s
      when 'commit', 'apply'
        unless Utils.check_input_lppsource(lpp_source).success?
          raise('"lpp_source" does not exist as NIM resource')
        end
        # when 'reject'
        # nothing
      else
        raise('"mode" must be either "commit", "apply", or "reject"')
      end
    else
      # nothing
    end

    # Depending on the action attribute, interpretation of ensure is not the same
    case action.to_s
    when 'status'
      Log.log_debug('targets_array =' + targets_array.to_s)
      @targets_to_apply = targets_array
      Log.log_debug('targets_to_apply=' + @targets_to_apply.to_s)
      returned = resource[:ensure].to_s != 'present'
      if resource[:ensure].to_s == 'absent'
        returned = false
        # to perform status in all cases.
      end

    when 'install'
      # set the default values
      returned = resource[:ensure].to_s == 'present'

      # check the presence or the absence of filesets on each target
      filesets = Utils.get_filesets_of_lppsource(lpp_source)
      Log.log_debug('Checking the presence or the absence of filesets on each target. Takes some time ... ')

      # nim -o lslpp -a filesets="openssl.base openssh.base.server"
      #   -a lslpp_flags=La quimby05
      targets_array.each do |target|
        begin
          Log.log_debug('Checking the presence or the absence of filesets on ' + target + '. Takes some time ... ')
          nim('-o', 'lslpp', '-a', "filesets=\"#{filesets}\"", \
              '-a', 'lslpp_flags=La', target.to_s)
          if resource[:ensure].to_s == 'present'
            Log.log_debug("All filesets already installed on #{target}")
            # do not change default value
          elsif resource[:ensure].to_s == 'absent'
            Log.log_debug("At least one fileset not yet removed on #{target}")
            # change default value
            returned = true
            # build list on which to apply
            @targets_to_apply.push(target.to_s)
            Log.log_debug('targets_to_apply1=' + @targets_to_apply.to_s)
          end
        rescue Puppet::ExecutionFailure => e
          Log.log_debug("Puppet::ExecutionFailure #{e}")
          if resource[:ensure].to_s == 'present'
            if e.inspect =~ /Connection refused/ || e.inspect =~ /connect Error/
              Log.log_debug("This #{target} is not accessible, skipping!")
            else
              Log.log_debug("At least one fileset missing on #{target}")
              # change default value
              returned = false
              # build list on which to apply
              @targets_to_apply.push(target.to_s)
              Log.log_debug('targets_to_apply2=' + @targets_to_apply.to_s)
            end
          elsif resource[:ensure].to_s == 'absent'
            if e.inspect =~ /Connection refused/ || e.inspect =~ /connect Error/
              Log.log_debug("This #{target} is not accessible, skipping!")
            else
              Log.log_debug("All filesets already removed on #{target}")
              # do not change default value
            end
          end
        end
      end

      # conclusion
      if resource[:ensure].to_s == 'present'
        if returned
          Log.log_debug('All filesets already installed on all ' + targets_array.to_s)
        else
          Log.log_debug('At least one fileset is to be installed on ' + @targets_to_apply.to_s)
        end
      elsif !returned
        Log.log_debug('All filesets already removed from all ' + targets_array.to_s)
      else
        Log.log_debug('At least one fileset needs to be removed on ' + @targets_to_apply.to_s)
      end

    when 'update'
      Log.log_debug('targets_array=' + targets_array.to_s)
      @targets_to_apply = targets_array
      Log.log_debug('targets_to_apply=' + @targets_to_apply.to_s)
      if mode == 'update' || mode == 'apply' || mode == 'commit'
        if resource[:ensure].to_s == 'present'
          returned = false
          Log.log_debug('To perform update')
          # to do update
        elsif resource[:ensure].to_s == 'absent'
          returned = false
          # to do nothing
          Log.log_info('Nothing to be done')
        end
      elsif mode == 'reject'
        if resource[:ensure].to_s == 'present'
          returned = true
          # to do nothing
          Log.log_info('Nothing to be done')
        elsif resource[:ensure].to_s == 'absent'
          returned = true
          Log.log_debug('To remove update : perform reject')
          # to do reject
        end
      end

    when 'reboot'
      Log.log_debug('targets_array =' + targets_array.to_s)
      @targets_to_apply = targets_array
      Log.log_debug('targets_to_apply=' + @targets_to_apply.to_s)
      returned = resource[:ensure].to_s != 'present'
      if resource[:ensure].to_s == 'absent'
        returned = true
        # to do nothing
      end

    else
      raise('action must be either "status", "install", "update", or "reboot"')

    end
    Log.log_info('Provider nimpush "exists!" method returning ' + returned.to_s)
    returned
  end

  # ###########################################################################
  #
  #
  # ###########################################################################
  def create
    Log.log_info("Provider nimpush 'create' method : doing : \"#{resource[:ensure]}\" for \"#{resource[:action]}\" \
action on \"#{resource[:targets]}\" targets with \"#{resource[:lpp_source]}\" lpp_source.")
    #
    action = resource[:action].to_s
    sync = resource[:sync].to_s
    sync_option = if sync == 'no'
                    'async=yes'
                  else
                    # default value
                    'async=no'
                  end
    preview = resource[:preview].to_s

    Log.log_debug('targets_to_apply=' + @targets_to_apply.to_s)
    targets_array = @targets_to_apply
    Log.log_debug('targets_array=' + targets_array.to_s)
    lpp_source = resource[:lpp_source].to_s

    # depending on the action attribute, NIM action is not the same
    case action.to_s
    when 'status'
      Log.log_debug('Doing status')
      results_status = {}
      targets_array.each do |target|
        status_output = Utils.status(target)
        Log.log_debug('target=' + target)
        status_output.keys.each { |key|
          Log.log_debug(' ' + key + '=>' + status_output[key])
        }
        results_status[target] = status_output
      end
      # persist to yaml
      result_yml_file = 'status.yml'
      File.write(result_yml_file, results_status.to_yaml)

    when 'install'
      Log.log_debug('Installing the lpp_source')
      installp_flags = '-acNgXY'
      installp_flags += 'p' if preview == "yes"
      begin
        Log.log_debug('Nim.cust_install')
        Nim.cust_install(lpp_source, sync_option, installp_flags, targets_array)
        Log.log_debug('Nim.cust_install')
      rescue Nim::NimCustOpError => e
        Log.log_err("NimCustOpError #{e} " + e.to_s)
        Log.log_err("Could not install #{lpp_source} on " + targets_array.to_s)
      end

    when 'update'
      Log.log_debug('Updating the lpp_source')
      mode = resource[:mode].to_s
      Log.log_debug("sync_option=\"#{sync_option}\"")

      if mode.to_s == 'apply'
        installp_flags = '-agXY'
        installp_flags += 'p' if preview == "yes"
        begin
          Log.log_debug('Nim.cust_update')
          Nim.cust_update(lpp_source, sync_option, installp_flags, targets_array)
          Log.log_debug('Nim.cust_update')
        rescue Nim::NimCustOpError => e
          Log.log_err("NimCustOpError #{e} " + e.to_s)
          Log.log_err("Could not update #{lpp_source} on " + targets_array.to_s)
        end

      elsif mode.to_s == 'commit'
        installp_flags = '-cgXY'
        installp_flags += 'p' if preview == "yes"
        begin
          Log.log_debug('Nim.maint')
          Nim.maint('all', sync_option, installp_flags, targets_array)
          Log.log_debug('Nim.maint')
        rescue Nim::NimMaintOpError => e
          Log.log_err("NimMaintOpError #{e} " + e.to_s)
          Log.log_err("Could not commit all filesets on " + target)
        end
      end

    when 'reboot'
      Log.log_debug('Doing the reboot')
      begin
        Log.log_debug('Nim.reboot')
        Nim.reboot(targets_array)
        Log.log_debug('Nim.reboot')
      rescue Nim::NimRebootOpError => e
        Log.log_err("NimRebootOpError #{e} " + e.to_s)
        Log.log_err('Could not reboot ' + targets_array.to_s)
      end
      Log.log_debug("Reboot of \"#{targets_array}\" lpars launched")

    else
      raise('"action"" must be either "status", install", "update", or "reboot"')

    end
    Log.log_debug('End of nimpush.create')
  end

  # ###########################################################################
  #
  #
  # ###########################################################################
  def destroy
    Log.log_info("Provider nimpush 'destroy' method : doing : \"#{resource[:ensure]}\" \
for \"#{resource[:action]}\" action on \"#{resource[:targets]}\" \
targets with \"#{resource[:lpp_source]}\" lpp_source.")
    #
    action = resource[:action].to_s
    sync = resource[:sync].to_s
    preview = resource[:preview].to_s

    Log.log_debug('targets_to_apply=' + @targets_to_apply.to_s)
    targets_array = @targets_to_apply
    Log.log_debug('targets=' + targets_array.to_s)

    sync_option = if sync.to_s == 'no'
                    'async=yes'
                  else
                    # default value
                    'async=no'
                  end

    # depending on the action attribute, NIM action is not the same
    case action
    when 'status'
      Log.log_debug('Doing status')
      targets_array.each do |target|
        status_output = Utils.status(target)
        Log.log_debug('target=' + target + ' ' + status_output.to_s)
      end

    when 'install'
      Log.log_debug('Uninstalling the lpp_source')
      lpp_source = resource[:lpp_source].to_s

      # builds list of filesets of this lpp_source
      filesets = Utils.get_filesets_of_lppsource(lpp_source)
      begin
        installp_flags = '-Iu'
        installp_flags += 'p' if preview == "yes"
        Log.log_debug('Nim.maint')
        Nim.maint(filesets, sync_option, installp_flags, targets_array)
        Log.log_debug('Nim.maint')
      rescue Nim::NimMaintOpError => e
        Log.log_err("NimMaintOpError #{e} " + e.to_s)
        Log.log_err("Could not remove #{filesets} on " + targets_array.to_s)
      end

    when 'update'
      Log.log_debug('Updating')
      Log.log_debug('Doing the remove of the update : reject')

      sync = resource[:sync].to_s
      mode = resource[:mode].to_s

      Log.log_debug("sync_option=\"#{sync}\"")

      if mode == 'reject'
        #  "filesets=devices.common.IBM.fc.rte
        #    devices.pci.df1000f7.com" -a installp_flags=rBX quimby05
        installp_flags = '-rBX'
        installp_flags += 'p' if preview == "yes"
        # it is needed to build the list of filesets to be rejected :
        #  this is the list of filesets of the lpp_source which are APPLIED only
        # this list is to be built per target
        filesets_per_target = Utils.get_targets_applied_filesets(targets_array)
        Log.log_debug("installp_flags=\"#{installp_flags}\"")
        targets_array.each do |target|
          filesets = filesets_per_target[target]
          Log.log_debug("filesets=\"#{filesets}\"")
          # 'array_target' needed to build an array of just one target
          array_target = []
          begin
            Log.log_debug('Start of Nim.maint')
            array_target.push(target)
            Nim.maint(filesets, sync_option, installp_flags, array_target)
            Log.log_debug('End of Nim.maint')
          rescue Nim::NimMaintOpError => e
            Log.log_err("NimMaintOpError #{e} " + e.to_s)
            Log.log_err("Could not reject #{filesets} on " + target)
          end
        end
      end

    when 'reboot'
      Log.log_info('Nothing to be done : not supported')

    else
      raise('"action" must be either "status", install", "update", or "reboot"')
    end
    Log.log_debug('End of nimpush.destroy')
  end
end
