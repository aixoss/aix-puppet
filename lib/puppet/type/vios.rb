require_relative '../../puppet_x/Automation/Lib/Vios.rb'
require_relative '../../puppet_x/Automation/Lib/Log.rb'

# ##############################################################################
# name : "vios" custom-type
# description : this custom-type enables to automate VIOS install and update (and
#  more) through nim commands : NIM push from a NIM server to a list of VIOS.
# ##############################################################################
Puppet::Type.newtype(:vios) do
  @doc = 'To manage all simple vios actions.'

  include Automation::Lib

  # ############################################################################
  #
  # ############################################################################
  ensurable do
    defaultvalues
    defaultto :present
  end

  # ############################################################################
  #
  # ############################################################################
  newparam(:name, :namevar => true) do
  end

  # ############################################################################
  #
  # ############################################################################
  newparam(:lpp_source) do
    desc '"lpp_source" attribute: name of the NIM lpp_source resource \
used to perform update or install'
    validate do |values|
      raise('"lpp_source" name \"' + values + '\" is too long (' +
                values.length.to_s + '), max is 39 characters') \
        if values.length > 39
    end
  end

  # ############################################################################
  # :vios_pairs is a attribute giving the VIOS pairs on which to apply action
  # Pairs must be given inside brackets, as following: (vios1,vios2)
  # Only valid targets are kept, targets need to be pingable,
  #  accessible through c_rsh, in a proper NIM state
  # ############################################################################
  newparam(:vios_pairs) do
    desc '"vios_pairs" attribute: list of vios pairs on which to perform action'

    kept = []
    suppressed = []

    validate do |values|
      Log.log_debug('values=' + values.to_s)
      # To parse input
      results = values.scan(/\([\w\_\-]+,[\w\_\-]+\)/)
      # v2
      #  if values="(vios11,vios12),(vios21,vios22),(vios31,vios32)"
      #  results=[["vios11","vios12"], ["vios21","vios22"], ["vios31","vios32"]]
      Log.log_debug('results=' + results.to_s)
      results.each do |result|
        Log.log_debug('result=' + result.to_s)
        viospair = result.scan(/[\w\_\-]+/)
        # if result="(vios31,vios32)"
        # viospair=["vios31", "vios32"]
        viospair.each do |vios|
          Log.log_debug('vios=' + vios.to_s)
        end
        Vios.check_input_viospair(viospair, kept, suppressed)
      end

      Log.log_err('"vios_pairs" which cannot be kept : ' + suppressed.to_s)
      Log.log_info('"vios_pairs" which can be kept : ' + kept.to_s)
    end

    munge do |_values|
      kept
    end
  end

  # ############################################################################
  # :actions attribute to choose actions to beperformed
  #
  # Check :actions against a short list, provide a default
  # ############################################################################
  newparam(:actions) do
    desc '"actions" attribute: actions to be performed on vios. \
 Possible actions : "check", "status", "save", update", "restore"'

    param_actions = []

    # To parse input
    validate do |values|
      Log.log_debug('values=' + values.to_s)
      param_actions = values.scan(/\w+/)
      Log.log_debug('param_actions=' + param_actions.to_s)
      invalid_actions = ''
      param_actions.each do |action|
        Log.log_debug('action=' + action.to_s)
        if action.to_s != 'check' &&
            action.to_s != 'status' &&
            action.to_s != 'save' &&
            action.to_s != 'update' &&
            action.to_s != 'restore'
          Log.log_debug('invalid_actions=' + invalid_actions)
          invalid_actions += ' action=' + action
        end
      end

      raise('"actions" contains invalid actions :' +
                invalid_actions) unless invalid_actions.empty?
    end

    munge do |_values|
      param_actions
    end

  end

  #   # ############################################################################
  #   # :alt_disk attribute to choose disks to be used to perform alt_disk_copy
  #   #  disk needs to be given per vios, therefore we have this syntax
  #   #  vios1:alt_disk1;vios2:alt_disk2;vios3:alt_disk3;  etc
  #   # A control is performed to check that given disk are ok for this operation
  #   # ############################################################################
  #   newparam(:alt_disks) do
  #     desc '"alt_disks" attribute: simple syntax to provide disk to be used \
  # per vios to perform alt_disk_copy"'
  #
  #     vios_disks = []
  #     invalid_vios_disks = []
  #     valid_vios_disks = []
  #
  #     # To parse input
  #     validate do |values|
  #       Log.log_debug('values=' + values.to_s)
  #       # To parse input
  #       vios_disks = values.scan(/\w+:\w+/)
  #       #
  #       Log.log_debug('vios_disks=' + vios_disks.to_s)
  #       vios_disks.each do |vios_disk|
  #         ret = 0
  #         Log.log_debug('vios_disk=' + vios_disk.to_s)
  #         vios, disk = vios_disk.split(':')
  #         if disk.nil? or disk.empty?
  #
  #         end
  #       end
  #       vios_disks.each do |vios_disk|
  #         ret = 0
  #         Log.log_debug('vios_disk=' + vios_disk.to_s)
  #         vios, disk = vios_disk.split(':')
  #         ret = Vios.check_vios_disk(vios, disk)
  #         if ret == 1
  #           invalid_vios_disks.push(vios_disk)
  #         else
  #           valid_vios_disks.push(vios_disk)
  #         end
  #       end
  #
  #       Log.log_err('"alt_disks" contains disks invalid to perform alt_disk_copy operation :' +
  #                       invalid_vios_disks.to_s)
  #       Log.log_info('"alt_disks" contains disks valid to perform alt_disk_copy operation :' +
  #                        valid_vios_disks.to_s)
  #     end
  #
  #     munge do |_values|
  #       valid_vios_disks
  #     end
  #
  #   end
  #
  #   # ############################################################################
  #   # :vios attribute to provide vios name on which alt_disk_copy needs to be done
  #   #   returning vios1:alt_disk1;vios1:alt_disk2;vios2:alt_disk2;  etc
  #   #  to indicate the candidate disks which can be used
  #   # ############################################################################
  #   newparam(:vios) do
  #     desc '"vios" attribute: vios names on which to perform alt_disk_copy"'
  #
  #     vios_names_disks = []
  #
  #     # To parse input
  #     validate do |values|
  #       Log.log_debug('values=' + values.to_s)
  #       # To parse input
  #       vios_name_array = values.split(':')
  #       #
  #       Log.log_debug('vios_name_array=' + vios_name_array.to_s)
  #       vios_names_disks = Vios.find_best_alt_disks(vios_name_array)
  #       Log.log_info('vios_names_disks='+vios_names_disks.to_s)
  #     end
  #
  #     munge do |_values|
  #       vios_names_disks
  #     end
  #
  #   end

  # ############################################################################
  # :sync attribute to control if action is synchronous or asynchronous
  #
  # Check :sync against a short list, provide a default
  # ############################################################################
  newparam(:sync) do
    desc '"sync" attribute: synchronous if "yes"" or asynchronous if "no", \
useful only for "action=update"'
    defaultto :yes
    newvalues(:yes, :no)
  end

  # ############################################################################
  # :mode attribute to tell kind of update to be done : apply, commit, reject
  #
  # Check :mode against a short list, provide a default
  # ############################################################################
  newparam(:mode) do
    desc '"mode" attribute: update mode either "apply", \
or "reject", or "commit"". Useful only for "action=update"'
    defaultto :apply
    newvalues(:apply, :reject, :commit)
  end

  # ############################################################################
  # :preview attribute to perform operation in preview mode only
  #
  # Check :preview against a short list, provide a default
  # ############################################################################
  newparam(:preview) do
    desc '"preview" attribute: preview only if "yes", by default \
it is set to "no"'
    defaultto :no
    newvalues(:yes, :no)
  end

  # ############################################################################
  # Perform global consistency checks between attributes
  # ############################################################################
  validate do
    #
    actions = self[:actions]

    # what is done here : consistency between actions, mode and lpp_source
    if (actions.include? 'update') && (self[:mode] == :apply) && (self[:lpp_source].nil?)
      raise('"lpp_source" attribute: required when "actions" contains "update"" and mode
is "apply"')
    end

    # what is done here : consistency between actions and vios_pairs
    if (actions.include? 'check') && (self[:vios_pairs].nil? or self[:vios_pairs].empty?)
      raise('"vios_pairs" attribute : cannot be empty when "actions" contains "check"')
    end
    # what is done here : consistency between actions and vios_pairs
    if (actions.include? 'save') && (self[:vios_pairs].nil? or self[:vios_pairs].empty?)
      raise('"vios_pairs" attribute : cannot be empty when "actions" contains "save"')
    end
  end
end
