require_relative '../../../puppet_x/Automation/Lib/Log.rb'
require_relative '../../../puppet_x/Automation/Lib/Suma.rb'
require_relative '../../../puppet_x/Automation/Lib/Nim.rb'
require_relative '../../../puppet_x/Automation/Lib/Utils.rb'

# ##########################################################################
# name : suma provider of the download type
# description :
#  implement download above suma
# ##########################################################################
Puppet::Type.type(:download).provide(:suma) do
  include Automation::Lib

  commands :lsnim => '/usr/sbin/lsnim'
  commands :nim => '/usr/sbin/nim'
  commands :rm => '/bin/rm'

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
    Log.log_info("Provider suma exists! We want to realize : \
                 \"#{resource[:ensure]}\" for type=\"#{resource[:type]}\" \
into directory=\"#{resource[:root]}\" \
from=\"#{resource[:from]}\" to \"#{resource[:to]}\" \
lpp_source=\"#{resource[:lpp_source]}\" force=#{resource[:force]}.")
    creation_done = true
    Log.log_debug('Suma.new')
    @suma = Suma.new([resource[:root],
                      resource[:force],
                      resource[:from],
                      resource[:to],
                      resource[:type],
                      resource[:to_step],
                      resource[:lpp_source]])
    Log.log_info('dir_metadata=' + @suma.dir_metadata)
    Log.log_info('dir_lpp_sources=' + @suma.dir_lpp_sources)
    Log.log_info('lpp_source=' + @suma.lpp_source)

    if resource[:force].to_s == 'yes'
      creation_done = false
      begin
        location = Nim.get_location_of_lpp_source(@suma.lpp_source)
        Log.log_info('Nim.get_location_of_lpp_source' + @suma.lpp_source + ' : ' + location)
        unless location.nil? || location.empty?
          Log.log_info('Removing contents of NIM lpp_source' + @suma.lpp_source + ' : ' + location)
          FileUtils.rm_rf Dir.glob("#{location}/*")
        end
        Log.log_info('Removing NIM lpp_source ' + @suma.lpp_source)
        Log.log_info('nim -o remove')
        nim('-o', 'remove', @suma.lpp_source)
      rescue Puppet::ExecutionFailure => e
        Log.log_debug('nim Puppet::ExecutionFailure e=' + e.to_s)
      end
    elsif resource[:ensure].to_s != 'absent'
      begin
        Log.log_info('lsnim')
        lsnim('-l', @suma.lpp_source)
      rescue Puppet::ExecutionFailure => e
        Log.log_debug('lsnim Puppet::ExecutionFailure e=' + e.to_s)
        creation_done = false # this will trigger creation
      end
    end
    creation_done
  end

  # ###########################################################################
  #
  #
  # ###########################################################################
  def create
    Log.log_info("Provider suma create. Doing \"#{resource[:ensure]}\" \
for type=\"#{resource[:type]}\" into directory=\"#{resource[:root]}\" \
from=\"#{resource[:from]}\" to \"#{resource[:to]}\" \
lpp_source=\"#{resource[:lpp_source]}\".")

    Log.log_info('dir_metadata=' + @suma.dir_metadata)
    Log.log_info('dir_lpp_sources=' + @suma.dir_lpp_sources)
    Log.log_info('lpp_source=' + @suma.lpp_source)

    # TODO : check if preview can be skipped if "step_to => :download"
    Log.log_debug('suma.preview')
    missing = @suma.preview
    Log.log_debug('suma.preview missing=' + missing.to_s)
    if missing
      Log.log_debug('to_step=' + @suma.to_step.to_s)
      if @suma.to_step.to_s == 'download'
        Log.log_debug('suma.download')
        downloaded = @suma.download
        Log.log_debug('suma.download missing=' + missing.to_s)
      else
        Log.log_debug('not suma.download, only preview')
      end
    end

    if !missing || downloaded == 0
      Log.log_debug('Nim.define_lpp_source')
      Nim.define_lpp_source(@suma.lpp_source,
                            @suma.dir_lpp_sources,
                            'built by Puppet AixAutomation')
      Log.log_debug('Nim.define_lpp_source')
    end

    Log.log_debug('End of suma.create')
  end

  # ###########################################################################
  #
  #
  # ###########################################################################
  def destroy
    Log.log_info("Provider suma destroy. Doing \"#{resource[:ensure]}\" \
for type=\"#{resource[:type]}\" into directory=\"#{resource[:root]}\" \
from=\"#{resource[:from]}\" to \"#{resource[:to]}\" \
lpp_source=.\"#{resource[:lpp_source]}\".")

    Log.log_info('dir_metadata=' + @suma.dir_metadata)
    Log.log_info('dir_lpp_sources=' + @suma.dir_lpp_sources)
    Log.log_info('lpp_source=' + @suma.lpp_source)

    Log.log_debug('Cleaning directories')
    # TO BE DONE ON OPTION ?
    rm('-r', '-f', @suma.dir_lpp_sources)
    rm('-r', '-f', @suma.dir_metadata)

    Log.log_debug('Cleaning directories')

    Log.log_debug('Nim.remove_lpp_source')
    Nim.remove_lpp_source(@suma.lpp_source)
    Log.log_debug('Nim.remove_lpp_source')

    Log.log_debug('End of suma.destroy')
  end
end
