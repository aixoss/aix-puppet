require_relative '../../puppet_x/Automation/Lib/Utils.rb'

# ##########################################################################
# name : patchmngt type
# description : this custom type enables to automate AIX install and update
#  through NIM push from a NIM server to a list of LPARs
# comments : provide a good sample of what it is possible do to
#  when defining a custom type : validate methods either specific to one
#  param, one global, moreover we'll find one munge.
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
  #
  # ############################################################################
  newparam(:lpp_source) do
  end

  # ############################################################################
  # :targets is a parameter giving the LPARs on which to apply action
  #
  # Only valid targets are kept, targets nedd to be pingable,
  #  accessible thru c_rsh, in a proper NIM state
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
  # :action parameter to choose action to be applied
  #
  # Check :action against a short list, provide a default
  # ############################################################################
  newparam(:action) do
    desc '"action" parameter: simple action to perform on target : \
either "status", "update", "install", or "reboot"'
    defaultto :status
    newvalues(:status, :update, :install, :reboot,)
  end

  # ############################################################################
  # :sync parameter to control if action is sunchonous or asyncronous
  #
  # Check :sync against a short list, provide a default
  # ############################################################################
  newparam(:sync) do
    desc '"sync" parameter: synchronous if "yes"" or asynchronous if "no", \
useful only for "action=update"'
    defaultto :yes
    newvalues(:yes, :no)
  end

  # ############################################################################
  # :mode parameter to tell kind of update to be done
  #
  # Check :mode against a short list, provide a default
  # ############################################################################
  newparam(:mode) do
    desc '"mode" parameter: update mode either "update", or "apply", \
or "reject", or "commit"". Useful only for "action=update"'
    defaultto :update
    newvalues(:update, :apply, :reject, :commit)
  end

  # ############################################################################
  # Perform global consistency checks between parameters
  # ############################################################################
  validate do
    if ((self[:action] == :install) ||
        ((self[:action] == :update) &&
            ((self[:mode] == :update) ||
                (self[:mode] == :apply)))) &&
        (self[:lpp_source].nil?)
      raise('"lpp_source" parameter: required when action is "install" or \
when action is "update"" and mode is "update" or "apply"')
    end
  end
end
