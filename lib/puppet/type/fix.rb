require_relative '../../puppet_x/Automation/Lib/Log.rb'
require_relative '../../puppet_x/Automation/Lib/Utils.rb'
require_relative '../../puppet_x/Automation/Lib/Flrtvc.rb'

# ##########################################################################
# name : fix type
# description :
# ##########################################################################
Puppet::Type.newtype(:fix) do
  @doc = 'To manage all simple ifix functions.'
  feature :fix, 'The ability to manage simple ifix actions.', methods: [:fix]

  include Automation::Lib

  # #####################################################################################
  #
  # #####################################################################################
  ensurable do
    defaultvalues
    defaultto :present
  end

  # #####################################################################################
  #
  # #####################################################################################
  newparam(:name, :namevar => true) do
  end

  # #####################################################################################
  #
  # #####################################################################################
  newparam(:targets) do
    desc '"targets" parameter: list of lpar or vios on which to perform action'
    kept = []
    validate do |values|
      kept = []
      suppressed = []
      #Log.log_info("newparam(:targets) values="+values.to_s)
      Utils.check_input_targets(values, kept, suppressed)
      fail('targets kept is empty, but must not be empty ') \
        if kept.empty?
    end
    munge do |_values|
      #Log.log_info("newparam(:targets) _values="+_values.to_s)
      returned = Utils.string_separated(kept, ',')
      #Log.log_info("newparam(:targets) returned="+returned.to_s)
      returned
    end
  end

  # #####################################################################################
  #
  # #####################################################################################
  newparam(:root) do
    desc '"root" parameter: download root directory for ifix'
    validate do |value|
      fail('"root" needs to exist') \
        if Utils.check_directory(value) == -1
    end
  end

  # #####################################################################################
  #
  # #####################################################################################
  newparam(:to_step) do
    desc '"to_step" parameter possible values: "runFlrtvc", "parseFlrtvc",\
 "downloadFixes", "checkFixes", "buildResource", "installResource"'
    defaultto :installResource
    newvalues(:runFlrtvc, :parseFlrtvc, :downloadFixes, :checkFixes,
              :buildResource, :installResource)
  end

  # #####################################################################################
  #
  # #####################################################################################
  newparam(:level) do
    desc '"level" parameter possible values: "hiper", "sec", "all"'
    defaultto :all
    newvalues(:hiper, :sec, :all)
  end

  # #####################################################################################
  #
  # #####################################################################################
  newparam(:clean) do
    desc '"clean" parameter possible values: "yes" or "no"'
    defaultto :yes
    newvalues(:yes, :no)
  end

  # #####################################################################################
  #
  # #####################################################################################
  validate do
    # NEEDS TO BE TESTED AGAIN
    # if targets==null failure
    fail('"targets" needs to be set') \
        if self[:targets].nil? || self[:targets].empty?

    # if ensure==present and root==null failure
    fail('"root" needs to be set if "ensure=>present"') \
      if self[:ensure] == 'present' && (self[:root].nil? || self[:root].empty?)

    # if ensure=absent and clean==yes and root==null failure
    fail('"root" needs to be set if "ensure=>absent" and "clean=>yes"') \
      if self[:ensure] == 'absent' && self[:clean] == 'yes' && (self[:root].nil? || self[:root].empty?)
  end
end
