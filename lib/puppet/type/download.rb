require_relative '../../puppet_x/Automation/Lib/Utils.rb'
require_relative '../../puppet_x/Automation/Lib/Suma.rb'
require_relative '../../puppet_x/Automation/Lib/SpLevel.rb'
require_relative '../../puppet_x/Automation/Lib/Constants.rb'

# ##########################################################################
# name : 'download' custom-type
# description : this custom-type enables to automate download through
#  suma metadata/preview/download.
# ##########################################################################
Puppet::Type.newtype(:download) do
  @doc = 'To manage all simple download functions.'

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
  ##############################################################################
  newparam(:name, :namevar => true) do
  end

  # ############################################################################
  # :root is the download root directory
  # ############################################################################
  newparam(:root) do
    desc '"root" attribute: download root directory for updates'
    validate do |value|
      raise('"root" needs to exist') if Utils.check_directory(value) == -1
    end
  end

  # ############################################################################
  # :type is the type of suma download desired
  #
  # Check :type against a short list, provide a default
  # ############################################################################
  newparam(:type) do
    desc '"type" attribute: either "SP", "TL", "Latest", or "Meta"'
    defaultto :SP
    newvalues(:SP, :TL, :Latest, :Meta)
  end

  # ############################################################################
  # :lpp_source is the name of the NIM resource lpp_source built at the end
  #  of suma download. If ever it is not provided, a default value is generated
  #  with naming convention "PAA_<type>_<from>_<to>"
  # ############################################################################
  newparam(:lpp_source) do
    desc '"lpp_source" attribute: optional attribute, \
name of the lpp_source built, by default "PAA_<type>_<from>_<to>"'
    validate do |values|
      raise('"lpp_source" name \"' + values + '\" is too long (' + values.length.to_s + '), max is 39 characters') \
        if values.length > 39
    end
    defaultto ''
  end

  # ############################################################################
  # :from attribute is a parameter of the suma request, giving current level of
  #  the system
  # ############################################################################
  newparam(:from) do
    desc '"from" attribute: current level'
    defaultto ''
  end

  # ############################################################################
  # :to attribute is a parameter of the suma request, giving desired level of
  #  the system
  # ############################################################################
  newparam(:to) do
    desc '"to" attribute: desired level'
    defaultto ''
  end

  # ############################################################################
  #
  # ############################################################################
  newparam(:to_step) do
    desc '"to_step" attribute possible values: "preview", "download"'
    defaultto :download
    newvalues(:preview, :download)
  end

  # ############################################################################
  # :force attribute to force new download of suma metadata and lppsource
  #   If set to 'yes', all previous downloads are removed, so that everything
  #    is downloaded again from scratch.
  #   By default it is set to 'no', meaning all previous downloads are kept
  #    and reused. This can spare a lot of time.
  # Check :force against a short list, provide a default
  # ############################################################################
  newparam(:force) do
    desc '"force" attribute: possible values "yes", "no"'
    defaultto :no
    newvalues(:yes, :no)
  end

  # ############################################################################
  # Perform global consistency checks between attributes
  # ############################################################################
  validate do
    root_directory = ::File.join(Constants.output_dir,
                                 'facter')
    yml_file = ::File.join(root_directory,
                           'sp_per_tl.yml')
    # validate directories
    dir_metadata = ::File.join(self[:root], 'metadata', self[:from])
    raise(dir_metadata + ' needs to exist') if Utils.check_directory(dir_metadata) == -1

    dir_lppsource = ::File.join(self[:root], 'lpp_sources')
    raise(dir_lppsource + ' needs to exist') if Utils.check_directory(dir_lppsource) == -1

    from = self[:from]
    to = self[:to]

    if self[:ensure] == :present
      if self[:type] == :SP

        result = SpLevel.validate_sp_tl('from', from)
        raise('"' + from + '" "from" attribute is invalid. Check ' + yml_file + ' file.') unless result

        result = SpLevel.sp_tl_exists(from)
        raise('"' + from + '" "from" attribute is neither a known TL nor a known SP. Check ' + yml_file + ' file.') unless result

        result = SpLevel.validate_sp('to', to)
        raise('"' + to + '" "to" attribute is invalid. Check ' + yml_file + ' file.') unless result

        result = SpLevel.sp_exists(to)
        raise('"' + to + '" "to" attribute is not a known SP. Check ' + yml_file + ' file.') unless result

        Log.log_debug('Validation of type=SP from=' + from + ' to=' + to + ' OK.')
      elsif self[:type] == :TL

        # All these suma TL requests are legitimate
        # suma -x -a RqType=TL -a RqName=6100-06-00-1036 -a FilterML=6100-05-09-1228 -a Action=Preview -a DLTarget=/tmp/lpp_sources/TL/6100-05-09-1228/6100-06-00-1036
        # suma -x -a RqType=TL -a RqName=6100-06         -a FilterML=6100-05 -a Action=Preview -a DLTarget=/tmp/lpp_sources/TL/6100-05/6100-06
        # suma -x -a RqType=TL -a RqName=6100-06         -a FilterML=6100-05-09-1228 -a Action=Preview -a DLTarget=/tmp/lpp_sources/TL/6100-05-09-1228/6100-06
        # suma -x -a RqType=TL -a RqName=6100-06-00-1036 -a FilterML=6100-05 -a Action=Preview -a DLTarget=/tmp/lpp_sources/TL/6100-05/6100-06-00-1036
        result = SpLevel.validate_tl('from', from) && SpLevel.validate_tl('to', to)
        unless result
          result = SpLevel.validate_sp('from', from) && SpLevel.validate_tl('to', to)
          unless result
            result = SpLevel.validate_tl('from', from) && SpLevel.validate_sp('to', to)
          end
        end
        raise('"' + from + '" "from" attribute and "' + to + '" "to" attribute are not consistent for a TL request. Check ' + yml_file + ' file.') unless result

        # result = SpLevel.validate_sp_tl("to", to)
        # result = SpLevel.validate_tl('to', to)
        # raise('"' + to + '" "to" attribute is invalid. Check ' + yml_file + ' file.') unless result

        result = SpLevel.sp_tl_exists(from)
        raise('"' + from + '" "from" attribute is neither a known TL nor a known SP. Check ' + yml_file + ' file.') unless result

        result = SpLevel.sp_tl_exists(to)
        raise('"' + to + '" "to" attribute is neither a known TL nor a known SP. Check ' + yml_file + ' file.') unless result

        Log.log_debug('Validation of type=TL from=' + from + ' to=' + to + ' OK.')
      elsif self[:type] == :Latest

        result = SpLevel.validate_tl('from', from)
        raise('"' + from + '" "from" attribute is invalid. Check ' + yml_file + ' file.') unless result

        raise('"' + to + '" "to" attribute must not be specified if type is set to "Latest"') if to != ''

        result = SpLevel.tl_exists(from)
        raise('"' + from + '" "from" attribute is not a known TL. Check ' + yml_file + ' file.') unless result

        Log.log_debug('Validation of type=Latest from=' + from + ' OK.')
      end
    end
  end
end
