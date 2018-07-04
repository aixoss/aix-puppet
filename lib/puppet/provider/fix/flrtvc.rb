require_relative '../../../puppet_x/Automation/Lib/Utils.rb'
require_relative '../../../puppet_x/Automation/Lib/Log.rb'
require_relative '../../../puppet_x/Automation/Lib/Flrtvc.rb'
require_relative '../../../puppet_x/Automation/Lib/Constants.rb'

# ##########################################################################
# name : flrtvc provider of the fix type
# description :
#  implement fix about flrtvc
# ##########################################################################
Puppet::Type.type(:fix).provide(:flrtvc) do
  include Automation::Lib

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
    Log.log_info("Provider flrtvc 'exists?' method : we want to realize up to \"#{resource[:to_step]}\" :
\"#{resource[:ensure]}\" \
for targets=\"#{resource[:targets]}\" into directory=\"#{resource[:root]}\"")
    #
    returned = true
    returned = false\
if resource[:ensure].to_s == 'present' || resource[:to_step].to_s == 'status'
    Log.log_info('Provider flrtvc "exists!" method returning ' + returned.to_s)
    returned
  end

  # ###########################################################################
  #
  # rubocop:disable Metrics/BlockNesting
  # ###########################################################################
  def create
    Log.log_info("Provider flrtvc 'create' method : doing up \
to \"#{resource[:to_step]}\" : \"#{resource[:ensure]}\" \
for targets=\"#{resource[:targets]}\" into directory=\"#{resource[:root]}\"")
    #
    targets_str = resource[:targets]
    root = resource[:root]
    to_step = resource[:to_step]
    level = resource[:level]
    force = resource[:force]
    @flrtvc = Flrtvc.new([targets_str, root, to_step, level, force])
    targets_array = targets_str.split(',')

    targets_array.each do |target|
      step = :status
      Log.log_debug('target=' + target + ' doing :' + step.to_s)
      @flrtvc.run_step(step, target, target + '_StatusBeforeEfixInstall.yml')
      Log.log_debug('target=' + target + ' done  :' + step.to_s)

      #
      step = :installFlrtvc
      Log.log_debug('target=' + target + ' doing :' + step.to_s)
      returned = @flrtvc.run_step(step, target)
      Log.log_debug('target=' + target + ' done  :' + step.to_s)
      next if to_step == :installFlrtvc

      #
      step = :runFlrtvc
      if returned == 0
        Log.log_debug('target=' + target + ' doing :' + step.to_s)
        flrtvc_report = @flrtvc.run_step(step, target)
        Log.log_debug('target=' + target + ' done  :' + step.to_s)
        next if to_step == :runFlrtvc

        #
        step = :parseFlrtvc
        if !flrtvc_report.nil? && !flrtvc_report.strip.empty?
          Log.log_debug('target=' + target + ' doing :' + step.to_s)
          download_urls = @flrtvc.run_step(step, target, flrtvc_report)
          Log.log_debug('target=' + target + ' done  :' + step.to_s)

          #
          next if to_step == :parseFlrtvc
          step = :downloadFixes
          if !download_urls.nil? && !download_urls.empty?
            Log.log_debug('target=' + target + ' doing :' + step.to_s)
            fixes_of_target = @flrtvc.run_step(step, target, download_urls)
            Log.log_debug('target=' + target + ' done  :' + step.to_s)

            #
            next if to_step == :downloadFixes
            step = :checkFixes
            if !fixes_of_target.nil? && !fixes_of_target.empty?
              Log.log_debug('target=' + target + ' doing :' + step.to_s)
              sorted_fixes_by_pkgdate = @flrtvc.run_step(step, target, fixes_of_target)
              Log.log_debug('target=' + target + ' done  :' + step.to_s)

              #
              next if to_step == :checkFixes
              step = :buildResource
              if !sorted_fixes_by_pkgdate.nil? && !sorted_fixes_by_pkgdate.empty?
                Log.log_info('target=' + target + ' ' + step.to_s)
                sorted_fixes_by_pkgdate.each do |sorted_fix_by_pkgdate|
                  Log.log_info(' sorted_fix_by_pkgdate=' +
                                    sorted_fix_by_pkgdate.to_s)
                end
                nim_resource_and_sorted_fixes = @flrtvc.run_step(step,
                                                                 target,
                                                                 sorted_fixes_by_pkgdate)
                Log.log_debug('target=' + target + ' done  :' +
                                  step.to_s +
                                  ' nim_resource_and_sorted_fixes=' +
                                  nim_resource_and_sorted_fixes.to_s)

                #
                next if to_step == :buildResource
                step = :installFixes
                if !nim_resource_and_sorted_fixes.nil? && !nim_resource_and_sorted_fixes.empty?
                  Log.log_debug('target=' + target + ' doing :' + step.to_s)
                  @flrtvc.run_step(step, target, nim_resource_and_sorted_fixes)
                  Log.log_debug('target=' + target + ' done  :' + step.to_s)
                else
                  Log.log_debug('target=' + target + ' skip  :' + step.to_s)
                end

                #
                step = :status
                Log.log_debug('target=' + target + ' doing :' + step.to_s)
                @flrtvc.run_step(step, target, target + '_StatusAfterEfixInstall.yml')
                Log.log_debug('target=' + target + ' done  :' + step.to_s)

              else
                Log.log_debug('target=' + target + ' skip  :' + step.to_s)
              end
            else
              Log.log_debug('target=' + target + ' skip  :' + step.to_s)
            end
          else
            Log.log_debug('target=' + target + ' skip  :' + step.to_s)
          end
        else
          Log.log_debug('target=' + target + ' skip  :' + step.to_s)
        end
      else
        Log.log_debug('target=' + target + ' skip  :' + step.to_s)
      end
    end

    Log.log_debug('End of flrtvc.create')
  end

  # ###########################################################################
  # rubocop:enable Metrics/BlockNesting
  #
  # ###########################################################################
  def destroy
    Log.log_info("Provider flrtvc 'destroy' method : doing \"#{resource[:ensure]}\" \
for targets=\"#{resource[:targets]}\" and force=\"#{resource[:force]}\" \
directory=\"#{resource[:root]}\"")
    #
    targets_str = resource[:targets]
    @flrtvc = Flrtvc.new([targets_str, resource[:root]])
    targets_array = targets_str.split(',')

    targets_array.each do |target|
      step = :status
      Log.log_debug('target=' + target + ' doing :' + step.to_s)
      @flrtvc.run_step(step, target, target + '_StatusBeforeEfixRemoval.yml')
      Log.log_debug('target=' + target + ' done  :' + step.to_s)

      step = :removeFixes
      Log.log_debug('target=' + target + ' doing :' + step.to_s)
      @flrtvc.run_step(step, target)
      Log.log_debug('target=' + target + ' done  :' + step.to_s)

      #
      step = :status
      Log.log_debug('target=' + target + ' doing :' + step.to_s)
      @flrtvc.run_step(step, target, target + '_StatusAfterEfixRemoval.yml')
      Log.log_debug('target=' + target + ' done  :' + step.to_s)
    end

    Log.log_debug('flrtvc.removing nim resources')
    @flrtvc.remove_nim_resources
    Log.log_debug('flrtvc.removed nim resources')

    Log.log_debug('flrtvc.removing downloaded efix files')
    @flrtvc.remove_downloaded_files
    Log.log_debug('flrtvc.removed downloaded efix files')

    Log.log_debug('End of flrtvc.destroy')
  end
end
