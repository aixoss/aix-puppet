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
    Log.log_info("Provider suma 'exists?' method : we want to realize : \"#{resource[:ensure]}\" for \
type=\"#{resource[:type]}\" into directory=\"#{resource[:root]}\" from=\"#{resource[:from]}\" \
to \"#{resource[:to]}\" lpp_source=\"#{resource[:lpp_source]}\" force=#{resource[:force]}.")
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
        Log.log_info('Nim.get_location_of_lpp_source ' + @suma.lpp_source + ' : ' + location)
        unless location.nil? || location.empty?
          Log.log_info('Removing contents of NIM lpp_source ' + @suma.lpp_source + ' : ' + location)
          FileUtils.rm_rf Dir.glob("#{location}/*")
          Log.log_info('Removing NIM lpp_source ' + @suma.lpp_source)
          Nim.remove_lpp_source(@suma.lpp_source)
        end
      rescue Puppet::ExecutionFailure => e
        Log.log_debug('NIM Puppet::ExecutionFailure e=' + e.to_s)
      end
    elsif resource[:ensure].to_s != 'absent'
      exists = Nim.lpp_source_exists?(@suma.lpp_source)
      if exists
        Log.log_info('NIM lpp_source resource ' + @suma.lpp_source + ' already exists, suma steps not necessary.')
        Log.log_info('You can force thru \'force => "yes"\' a new suma download and new creation of NIM lpp_source resource.')
      else
        Log.log_info('NIM lpp_source resource ' + @suma.lpp_source + ' does not exists.')
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
    Log.log_info("Provider suma 'create' method : doing \"#{resource[:ensure]}\" \
for type=\"#{resource[:type]}\" into directory=\"#{resource[:root]}\" \
from=\"#{resource[:from]}\" to \"#{resource[:to]}\" \
lpp_source=\"#{resource[:lpp_source]}\".")

    Log.log_info('dir_metadata=' + @suma.dir_metadata)
    Log.log_info('dir_lpp_sources=' + @suma.dir_lpp_sources)
    Log.log_info('lpp_source=' + @suma.lpp_source)

    # TODO : check if preview can be skipped if "step_to => :download"
    Log.log_debug('Launching now suma.preview')
    begin
      missing = @suma.preview
      Log.log_debug('suma.preview shows that missing=' + missing.to_s)
      if missing
        if @suma.to_step.to_s == 'download'
          Log.log_debug('Launching now suma.download')
          downloaded = @suma.download
          Log.log_debug('downloaded=' + downloaded.to_s)
        else
          Log.log_debug('suma.download not necessary as only preview is required')
        end
      else
        Log.log_debug('suma.download not necessary as preview shows nothing is missing ')
      end
      #
      exists = Nim.lpp_source_exists?(@suma.lpp_source)
      if !exists
        Log.log_debug('Nim.define_lpp_source')
        Nim.define_lpp_source(@suma.lpp_source,
                              @suma.dir_lpp_sources,
                              'built by Puppet AixAutomation')
      else
        Log.log_info('NIM lpp_source resource ' + @suma.lpp_source + ' already exists, creation not done.')
        Log.log_info('You can force thru \'force => "yes"\' a new suma download and new creation of NIM lpp_source resource.')
      end

    rescue SumaPreviewError, SumaDownloadError => e
      Log.log_err('Exception ' + e.to_s)
    end

    Log.log_debug('End of suma.create')
  end

  # ###########################################################################
  #
  #
  # ###########################################################################
  def destroy
    Log.log_info("Provider suma 'destroy' method : doing \"#{resource[:ensure]}\" \
for type=\"#{resource[:type]}\" into directory=\"#{resource[:root]}\" \
from=\"#{resource[:from]}\" to \"#{resource[:to]}\" \
lpp_source=.\"#{resource[:lpp_source]}\".")

    Log.log_debug('dir_metadata=' + @suma.dir_metadata)
    Log.log_debug('dir_lpp_sources=' + @suma.dir_lpp_sources)
    Log.log_debug('lpp_source=' + @suma.lpp_source)

    Log.log_info('Cleaning directories' + @suma.dir_lpp_sources + ' and ' + @suma.dir_metadata)
    rm('-r', '-f', @suma.dir_lpp_sources)
    rm('-r', '-f', @suma.dir_metadata)
    Log.log_debug('Cleaning directories done')

    Log.log_info('Removing NIM lpp_source resource ' + @suma.lpp_source)
    Nim.remove_lpp_source(@suma.lpp_source)
    Log.log_debug('Removing NIM lpp_source resource done')

    Log.log_debug('End of suma.destroy')
  end

end
