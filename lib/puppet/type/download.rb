require_relative '../../puppet_x/Automation/Lib/Utils.rb'
require_relative '../../puppet_x/Automation/Lib/Suma.rb'
require_relative '../../puppet_x/Automation/Lib/SpLevel.rb'

# ##########################################################################
# name : download type
# description :
# ##########################################################################
Puppet::Type.newtype(:download) do
  @doc = 'To manage all simple download functions.'
  feature :download, 'The ability to manage simple download actions.', :methods => [:download]

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
  ######################################################################################################
  newparam(:name, :namevar => true) do
  end

  # #####################################################################################
  #
  # #####################################################################################
  newparam(:root) do
    desc '"root" parameter: download root directory for updates'
    validate do |value|
      fail('"root" needs to exist') \
        if Utils.check_directory(value) == -1
    end
  end

  # #####################################################################################
  #
  # #####################################################################################
  newparam(:type) do
    desc '"type" parameter: either "SP", "TL", "Latest", or "Meta"'
    defaultto :SP
    newvalues(:SP, :TL, :Latest, :Meta)
  end

  # #####################################################################################
  #
  # #####################################################################################
  newparam(:lpp_source) do
    desc '"lpp_source" parameter: optional parameter, name of the lpp_source built,\
 by default "PAA_<type>_<from>_<to>"'
    defaultto ''
  end

  # #####################################################################################
  #
  # #####################################################################################
  newparam(:from) do
    desc '"from" parameter: current level'
    defaultto ''
  end

  # #####################################################################################
  #
  # #####################################################################################
  newparam(:to) do
    desc '"to" parameter: desired level'
    defaultto ''
  end

  # #####################################################################################
  #
  # #####################################################################################
  validate do

    # validate directories
    dir_metadata = self[:root] + '/metadata/' + self[:from]
    fail(dir_metadata + ' needs to exist') \
        if Utils.check_directory(dir_metadata) == -1

    dir_lppsource = self[:root] + '/lpp_sources'
    fail(dir_lppsource + ' needs to exist') \
        if Utils.check_directory(dir_lppsource) == -1

    from = self[:from]
    to = self[:to]

    if self[:type] == :SP

      result = SpLevel.validate_sp_tl('from', from)
      unless result
        fail('"from" parameter is invalid')
      end

      result = SpLevel.sp_tl_exists(from)
      unless result
        fail('"from" parameter is neither a known TL nor a known SP')
      end

      result = SpLevel.validate_sp('to', to)
      unless result
        fail('"to" parameter is invalid')
      end

      result = SpLevel.sp_exists(to)
      unless result
        fail('"to" parameter is not a known SP')
      end

    elsif self[:type] == :TL

      result = SpLevel.validate_tl('from', from)
      unless result
        fail('"from" parameter is invalid')
      end

      #result = SpLevel.validate_sp_tl("to", to)
      result = SpLevel.validate_tl('to', to)
      unless result
        fail('"to" parameter is invalid')
      end

      result = SpLevel.tl_exists(from)
      unless result
        fail('"from" parameter is not a known TL')
      end
      result = SpLevel.tl_exists(to)
      unless result
        fail('"to" parameter is not a known TL')
      end

    elsif self[:type] == :Latest

      result = SpLevel.validate_tl('from', from)
      unless result
        fail('"from" parameter is invalid')
      end

      if to != ''
        fail('"to" parameter must not be specified for Latest')
      end

      result = SpLevel.tl_exists(from)
      unless result
        fail('"from" parameter is not a known TL')
      end
    end
  end

end
