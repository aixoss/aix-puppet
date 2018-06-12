require_relative '../../../puppet_x/Automation/Lib/Utils.rb'
require_relative '../../../puppet_x/Automation/Lib/Log.rb'
require_relative '../../../puppet_x/Automation/Lib/Flrtvc.rb'

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
    Log.log_info("Provider flrtvc exists! We want to realize up to \
\"#{resource[:to_step]}\" : \"#{resource[:ensure]}\" \
for targets=\"#{resource[:targets]}\" into directory=\"#{resource[:root]}\"")
    returned = true
    returned = false\
if resource[:ensure].to_s == 'present' || resource[:to_step].to_s == 'status'
    Log.log_info('Provider flrtvc exists! returning ' + returned.to_s)
    returned
  end

  # ###########################################################################
  #
  #
  # ###########################################################################
  def create
    Log.log_info("Provider flrtvc create : doing up \
to \"#{resource[:to_step]}\" : \"#{resource[:ensure]}\" \
for targets=\"#{resource[:targets]}\" into directory=\"#{resource[:root]}\"")

    targets_str = resource[:targets]
    root = resource[:root]
    to_step = resource[:to_step]
    level = resource[:level]
    clean = resource[:clean]
    @flrtvc = Flrtvc.new([targets_str, root, to_step, level, clean])
    targets_array = targets_str.split(',')

    status_before = {}
    status_after = {}
    targets_array.each do |target|

      step = :status
      Log.log_debug('target=' + target + ' doing :' + step.to_s)
      flrtvc_report = @flrtvc.run_step(step, target)
      Log.log_debug('target=' + target + ' done  :' + step.to_s)
      #Log.log_debug('target=' + target + '\n' + flrtvc_report.to_s + '\n')
      status_before[target] = flrtvc_report

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
                Log.log_debug('target=' + target + ' doing :' + step.to_s +
                                  ' sorted_fixes_by_pkgdate=' +
                                  sorted_fixes_by_pkgdate.to_s)
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
                flrtvc_report = @flrtvc.run_step(step, target)
                Log.log_debug('target=' + target + ' done  :' + step.to_s)
                #Log.log_debug('target=' + target + '\n' + flrtvc_report.to_s + '\n')
                status_after[target] = flrtvc_report

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

    # display and persist status before
    if !status_before.nil? && !status_before.empty?
      Log.log_debug('status before=' + status_before.to_s)
      # Persist to yml
      status_before_yml_file = ::File.join(Constants.output_dir,
                                           'logs',
                                           'PuppetAix_StatusBefore.yml')
      File.write(status_before_yml_file, status_before.to_yaml)
      Log.log_debug('Refer to "' + status_before_yml_file + '" to have status at the start of "fix" ("flrtvc"
provider)')
    end

    # display and persist status after
    if !status_after.nil? && !status_after.empty?
      Log.log_debug('status after=' + status_after.to_s)
      # Persist to yml
      status_after_yml_file = ::File.join(Constants.output_dir,
                                          'logs',
                                          'PuppetAix_StatusAfter.yml')
      File.write(status_after_yml_file, status_after.to_yaml)
      Log.log_debug('Refer to "' + status_after_yml_file + '" to have status at the end of "fix" ("flrtvc" provider)')
    end

    Log.log_debug('End of flrtvc.create')
  end

  # ###########################################################################
  #
  #
  # ###########################################################################
  def destroy
    Log.log_info("Provider flrtvc destroy : doing \"#{resource[:ensure]}\" \
for targets=\"#{resource[:targets]}\" and clean=\"#{resource[:clean]}\" \
directory=\"#{resource[:root]}\"")

    targets_str = resource[:targets]
    @flrtvc = Flrtvc.new([targets_str, resource[:root]])

    Log.log_debug('flrtvc.removing ifix from lpar')
    @flrtvc.remove_ifixes
    Log.log_debug('flrtvc.removed ifix from lpar')

    Log.log_debug('flrtvc.removing nim resources')
    @flrtvc.remove_nim_resources
    Log.log_debug('flrtvc.removed nim resources')

    if resource[:clean] == 'yes'
      Log.log_debug('flrtvc.removing downloaded ifix files')
      @flrtvc.remove_downloaded_files
      Log.log_debug('flrtvc.removed downloaded ifix files')
    end

    Log.log_debug('End of flrtvc.destroy')
  end
end
