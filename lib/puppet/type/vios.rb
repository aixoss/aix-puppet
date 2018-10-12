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
  # :vios_pairs is an attribute giving the VIOS pairs on which to apply action
  # Pairs must be given inside brackets, as following: (vios1,vios2)
  # Several pairs can be given as following:(vios1,vios2),(vios3,vios4)
  # Only valid pairs are kept:
  #  - each member of the pair needs to be pingable,
  #  - each member of the pair needs to be accessible through c_rsh,
  #  - each member of the pair needs to be in a proper NIM state.
  # ############################################################################
  newparam(:vios_pairs) do
    desc '"vios_pairs" attribute: list of vios pairs on which to perform action'

    kept = []
    suppressed = []

    validate do |values|
      Log.log_debug('values=' + values.to_s)
      # To parse input
      results = values.scan(/\([\w\-]+,*[\w\-]+\)/)
      # v2
      #  if values="(vios11,vios12),(vios21,vios22),(vios31,vios32)"
      #  results=[["vios11","vios12"], ["vios21","vios22"], ["vios31","vios32"]]
      Log.log_debug('results=' + results.to_s)
      results.each do |result|
        Log.log_debug('result=' + result.to_s)
        vios_pair = result.scan(/[\w\-]+/)
        # if result="(vios31,vios32)"
        # vios_pair=["vios31", "vios32"]
        vios_pair.each do |vios|
          Log.log_debug('vios=' + vios.to_s)
        end
        Vios.check_input_vios_pair(vios_pair, kept, suppressed)
      end

      Log.log_err('"vios_pairs" which cannot be kept : ' + suppressed.to_s) if suppressed.length > 0
      Log.log_info('"vios_pairs" which can be kept : ' + kept.to_s)
    end

    munge do |_values|
      kept
    end
  end

  # ############################################################################
  # :vios_lpp_sources is a attribute giving for each vios the name of the
  #  lpp_sources to be used.
  # To enable association with vios, vios_lpp_sources must be given
  #  with following syntax: "vios1=lpp_source1,vios2=lpp_source2"
  # Check is done that vios are valid targets, and that lpp_sources are valid
  #  lpp_source.
  # Prepare an hashtable with vios as keys and lpp_source as values
  # ############################################################################
  newparam(:vios_lpp_sources) do
    desc '"vios_lpp_sources" attribute: names of the NIM lpp_source resources, \
associated to vios_pairs, used to perform update or install'
    h_vios_lppsources = {}

    #
    validate do |values|
      Log.log_debug('values=' + values.to_s)
      # To parse input
      vios_lppsources = values.scan(/[\w\-]+=\w+/)
      Log.log_debug('vios_lppsources=' + vios_lppsources.to_s)
      unless vios_lppsources.nil?
        vios_lppsources.each do |vios_lppsource|
          Log.log_debug('result=' + vios_lppsource.to_s)
          if vios_lppsource =~ /([\w\-]+)=(\w+)/
            vios = Regexp.last_match(1)
            Log.log_debug('vios=' + vios.to_s)
            unless Vios.check_vios(vios)
              raise('"vios_lpp_sources" "' + vios.to_s + '" vios is not a valid vios.')
            end
            lppsource = Regexp.last_match(2)
            Log.log_debug('lppsource=' + lppsource.to_s)
            unless lppsource.length <= 39
              raise('"vios_lpp_sources" "' + lppsource.to_s + '" lpp_source is too long (' +
                        lpp_source.length.to_s + '), max is 39 characters.')
            end
            unless Utils.check_input_lppsource(lppsource).success?
              raise('"vios_lpp_sources" "' + lppsource.to_s + '" lpp_source does not exist as NIM resource.')
            end
            h_vios_lppsources[vios.to_s] = lppsource.to_s
          end
        end
      end
    end

    #
    munge do |_values|
      Log.log_debug('h_vios_lppsources=' + h_vios_lppsources.to_s)
      h_vios_lppsources
    end
  end


  # ############################################################################
  # :actions attribute to choose actions to be performed
  #
  # Check :actions against a short list, provide a default
  # ############################################################################
  newparam(:actions) do
    desc '"actions" attribute: actions to be performed on vios. \
 Possible actions : "health", "check", "clean", "unmirror", "save", "autocommit", "update", "restore"'
    param_actions = []
    # To parse input
    validate do |values|
      Log.log_debug('values=' + values.to_s)
      param_actions = values.scan(/\w+/)
      Log.log_debug('param_actions=' + param_actions.to_s)
      invalid_actions = ''
      param_actions.each do |action|
        Log.log_debug('action=' + action.to_s)
        if action.to_s != 'health' &&
            action.to_s != 'check' &&
            action.to_s != 'clean' &&
            action.to_s != 'unmirror' &&
            action.to_s != 'save' &&
            action.to_s != 'autocommit' &&
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

  # ############################################################################
  # :options attribute to set options to be passed at update
  #  Possible options are :
  #   accept_licenses (default is to not accept license)
  #   preview (default is to commit)
  # Check :options against a short list, provide a default
  # ############################################################################
  newparam(:options) do
    desc '"options" attribute: options to be passed to update. \
 Possible options are : "accept_licenses, preview"'
    param_options = []
    # To parse input
    validate do |values|
      Log.log_debug('values=' + values.to_s)
      param_options = values.scan(/\w+/)
      Log.log_debug('param_options=' + param_options.to_s)
      invalid_options = ''
      param_options.each do |option|
        Log.log_debug('option=' + option.to_s)
        if option.to_s != 'accept_licenses' &&
            option.to_s != 'preview'
          Log.log_debug('invalid options=' + option.to_s)
          invalid_options += ' ' + option
        end
      end
      raise('"options" contains invalid options :' +
                invalid_options) unless invalid_options.empty?
    end

    munge do |_values|
      param_options
    end
  end

  # ############################################################################
  # :update_options attribute to set options to be passed at update
  #  Possible update options are :
  # https://www.ibm.com/support/knowledgecenter/en/ssw_aix_72/com.ibm.aix.install/nim_op_updateios.htm
  #   commit
  #   install
  #   remove
  #   reject
  #   cleanup
  # Check :update_options against a short list, provide a default
  # ############################################################################
  newparam(:update_options) do
    desc '"update_options" attribute: options to be passed to update. \
 Possible update_options is : "commit" \
 More values to be supported in future : "install", "commit", "remove", "reject", "cleanup"'
    defaultto :commit.to_s
    param_update_options = [:commit.to_s]
    # To parse input
    validate do |values|
      Log.log_debug('values=' + values.to_s)
      unless values.nil?
        param_update_options = values.scan(/\w+/)
        Log.log_debug('param_update_options=' + param_update_options.to_s)
        invalid_update_options = ''
        param_update_options.each do |update_option|
          Log.log_debug('update_option=' + update_option.to_s)
          if update_option.to_s != 'commit'
            # more values to be supported in future ?
            #          && update_option.to_s != 'install'
            #          && update_option.to_s != 'remove'
            #          && update_option.to_s != 'reject'
            #          && update_option.to_s != 'cleanup'
            Log.log_debug('invalid update_options=' + update_option.to_s)
            invalid_update_options += ' ' + update_option
          end
        end
        raise('"update_options" contains invalid update options :' +
                  invalid_update_options) unless invalid_update_options.empty?
      end

    end

    munge do |_values|
      param_update_options
    end
  end

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
  # :vios_altinst_rootvg is a attribute giving for each vios the name of the
  #  disk to be used to perform altinst_rootvg
  # To enable association with vios, altinst_rootvg disk must be given
  #  with following syntax: "vios1=hdisk1,vios2=hdisk2"
  # Check is done that disk provided are valid disk to be used for
  #  altinst_rootvg.
  # This parameter is not mandatory, disk can be choosen as well following
  #  other rules.
  # ############################################################################
  newparam(:vios_altinst_rootvg) do
    desc '"vios_altinst_rootvg" attribute: names of the disk, \
associated to vios, used to perform altinst_rootvg'
    h_vios_disks = {}

    #
    validate do |values|
      Log.log_debug('values=' + values.to_s)
      # To parse input
      vios_disks = values.scan(/[\w\-]+=\w+/)
      Log.log_debug('vios_disks=' + vios_disks.to_s)
      unless vios_disks.nil?
        vios_disks.each do |vios_disk|
          Log.log_debug('result=' + vios_disk.to_s)
          if vios_disk =~ /([\w\-]+)=(\w+)/
            vios = Regexp.last_match(1)
            Log.log_debug('vios=' + vios.to_s)
            unless Vios.check_vios(vios)
              raise('"vios_disks" "' + vios.to_s + '" vios is not a valid target.')
            end
            disk = Regexp.last_match(2)
            Log.log_debug('disk=' + disk.to_s)
            unless Utils.check_input_disk(vios, disk) != 0
              raise('"vios_disks" "' + disk.to_s + '" disk is not valid.')
            end
            h_vios_disks[vios.to_s] = disk.to_s
          end
        end
      end
    end

    #
    munge do |_values|
      Log.log_debug('h_vios_disks=' + h_vios_disks.to_s)
      h_vios_disks
    end
  end


  # ############################################################################
  # :altinst_rootvg_force attribute to control if save action can use potentially
  #   existing altinst_rootvg. Three possible values: :no, :yes, :reuse
  #   This attribute applies on all vios.
  #  :no  If one altinst_rootvg already exists, then it is kept, and
  #       therefore as taking a new one is not possible, the VIOS update
  #       is stopped. If none altinst_rootvg existed, a new one is taken,
  #       and best disk is chosen.
  #  :yes  Builds a new altinst_rootvg, and the previous one, if ever it
  #       exists, will be overridden. Same disk will be used prioritarily,
  #       if size allows, otherwise best disk is chosen.
  #  :reuse  If one one altinst_rootvg already exists, this one is
  #       considered as 'fresh' enough, and no new one is taken. If none
  #       existed, a new one is taken, and best disk is chosen.
  # Check :altinst_rootvg_force against a short list, provide a default
  # ############################################################################
  newparam(:altinst_rootvg_force) do
    desc '"force" attribute: "no", "yes", or "reuse", useful only for "action=save"'
    defaultto :no
    newvalues(:no, :yes, :reuse)
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

    unless actions.nil?
      # what is done here : consistency between actions, mode and lpp_source
      if (actions.include? 'update') && (self[:mode] == :apply) && (self[:vios_lpp_sources].nil?)
        raise('"vios_lpp_sources" attribute: required when "actions" contains "update"" and mode
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
end
