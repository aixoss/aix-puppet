require_relative '../../puppet_x/Automation/Lib/Utils.rb'

# ##########################################################################
# name : patchmngt type
# description : provide a good sample of what it is possible do to
#  with validate methods either specific to one param, one global
# Moreover we'll find one munge
# ##########################################################################
Puppet::Type.newtype(:patchmngt) do
  @doc = 'To manage all simple patchmngt actions \
(status,install/uninstall,update,reboot).'
  feature :patchmngt, 'The ability to manage actions on remote targets.', \
methods: [:patchmngt]

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
  # Check lpp_source exists as NIM resources
  # This check is removed, as it is checked before the lpp_source
  #  NIM resource has been built.
  # It is better to check existence of lpp_source dynamically
  #  therefore this check is moved into nimpush.rb
  # ############################################################################
  newparam(:lpp_source) do
  end

  # ############################################################################
  #
  # ############################################################################
  newparam(:targets) do
    desc '"targets" parameter: list of lpar or vios on which to perform action'
    kept = []
    suppressed = []
    validate do |values|
      Utils.check_input_targets(values, kept, suppressed)
      raise('"targets" is empty, but must not be empty') \
        if kept.empty?
    end
    munge do |_values|
      Utils.string_separated(kept, ' ')
    end
  end

  # ############################################################################
  #
  # ############################################################################
  newparam(:action) do
    desc '"action" parameter: simple action to perform on target : \
either "status", "update", "install", or "reboot"'
    defaultto :status
    newvalues(:status, :update, :install, :reboot,)
  end

  # ############################################################################
  #
  # ############################################################################
  newparam(:sync) do
    desc '"sync" parameter: synchronous if "yes"" or asynchronous if "no", \
useful only for "action=update"'
    defaultto :yes
    newvalues(:yes, :no)
  end

  # ############################################################################
  #
  # ############################################################################
  newparam(:mode) do
    desc '"mode" parameter: update mode either "update", or "apply", \
or "reject", or "commit"" useful only for "action=update"'
    defaultto :update
    newvalues(:update, :apply, :reject, :commit)
  end

  # ############################################################################
  #
  # ############################################################################
  validate do
    if (((self[:action] == :install) ||
        ((self[:action] == :update) &&
            ((self[:mode] == :update) ||
                (self[:mode] == :apply)))) &&
        (self[:lpp_source].nil?))
      raise('"lpp_source" parameter: required when action is "install" or \
when action is "update"" and mode is "update" or "apply"')
    end
  end
end
