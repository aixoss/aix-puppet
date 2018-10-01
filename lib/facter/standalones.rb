require_relative '../puppet_x/Automation/Lib/Constants.rb'
require_relative '../puppet_x/Automation/Lib/Log.rb'
require_relative '../puppet_x/Automation/Lib/Remote/c_rsh.rb'
#
# ##############################################################################
# name : 'standalones' factor
# param : none
# return : hash of standalones.
#  Two files are generated: "output/facter/standalones_skipped.yml" and
#  "output/facter/standalones_kept.yml" as result log.
# description : this facter builds a fact called 'standalones' containing a
#  hash with standalones names known by the NIM server as value.
#  Only the standalones used as 'targets' into manifests/init.pp file are tested.
#  Other tests performed on standalones are : ping, c_rsh, NIM parameters.
#  Only standalones satisfying these criteria are used by runtime.
# ##############################################################################
include Automation::Lib
include Automation::Lib::Remote
#
Facter.add('standalones') do
  setcode do
    Log.log_info('Computing "standalones" facter')

    # Retrieves from :applied_manifest facter list of targets used in manifests/init.pp
    applied_manifest = Facter.value(:applied_manifest)
    alltargets = applied_manifest['targets']

    standalones_kept = {}
    standalones_skipped = {}

    standalones_str = Facter::Core::Execution.execute("/usr/sbin/lsnim -t standalone | \
/bin/awk 'NR==FNR{print $1;next}{print $1}' | \
/bin/awk 'FNR!=1{print l}{l=$0};END{ORS=\"\";print l}' ORS=' '")
    standalones_array = standalones_str.split(' ')

    #
    standalones_array.each do |standalone|
      standalone_hash = {}
      #
      unless alltargets.include? standalone
        standalone_hash['WARNING'] = 'Standalone ' + standalone + ' is not used in "manifests/init.pp. Skipping"'
        standalones_skipped[standalone] = standalone_hash
        next
      end

      #### ping
      ping_cmd = '/usr/sbin/ping -c1 -w5 ' + standalone
      stdout, stderr, status = Open3.capture3(ping_cmd.to_s)
      Log.log_debug("ping_cmd=#{ping_cmd}")
      Log.log_debug("ping_status=#{status}")
      if status.success?
        Log.log_debug("ping_stdout=#{stdout}")
        ##### oslevel
        oslevel = ''
        oslevel_cmd = '/usr/bin/oslevel -s '
        remote_cmd_rc = Remote.c_rsh(standalone,
                                     oslevel_cmd,
                                     oslevel)
        # Log.log_debug('remote_cmd_rc=' + remote_cmd_rc.to_s + ' ' + remote_cmd_rc.class.to_s)
        if remote_cmd_rc == 0
          standalone_hash['oslevel'] = oslevel.strip

          # #### /etc/niminfo
          niminfo_str = ''
          nim_cmd = "/bin/cat /etc/niminfo | /bin/grep '=' | /bin/sed 's/export //g'"
          remote_cmd_rc = Remote.c_rsh(standalone,
                                       nim_cmd,
                                       niminfo_str)
          if remote_cmd_rc == 0
            niminfo_lines = niminfo_str.split("\n")
            niminfo_lines.each do |envvar|
              key, val = envvar.split('=')
              standalone_hash[key] = val
            end

            # #### Cstate from lsnim -l
            lsnim_str = Facter::Core::Execution.execute('/usr/sbin/lsnim -l ' +
                                                            standalone)
            lsnim_lines = lsnim_str.split("\n")
            keep_it = false
            lsnim_lines.each do |lsnim_line|
              # Cstate
              next unless lsnim_line =~ /^\s+Cstate\s+=\s+(.*)$/
              cstate = Regexp.last_match(1)
              standalone_hash['cstate'] = cstate
              keep_it = true if cstate == 'ready for a NIM operation'
            end

            if keep_it
              # Get status of efix on this standalone
              remote_cmd = "/bin/lslpp -e | /bin/sed '/STATE codes/,$ d'"
              remote_output = []
              remote_cmd_rc = Remote.c_rsh(standalone, remote_cmd, remote_output)
              if remote_cmd_rc == 0
                standalone_hash['lslpp -e'] = remote_output[0].chomp
              end

              # yeah, we keep it ! ping ok, lsnim ok, crsh ok, cstate ok
              standalones_kept[standalone] = standalone_hash
              # Log.log_debug('standalones[' + standalone + ']=' + standalone_hash.to_s)
            else
              standalone_hash['WARNING'] = 'Standalone ' + standalone + ' is not "ready for a NIM operation"'
              Log.log_warning('error on Cstate for : ' + standalone)
              standalones_skipped[standalone] = standalone_hash
            end
          else
            standalone_hash['WARNING'] = 'Standalone ' + standalone + ' cannot "' + nim_cmd + '"'
            Log.log_warning('error while doing "' + nim_cmd + '" on "' + standalone + '"')
            standalones_skipped[standalone] = standalone_hash
          end
        else
          standalone_hash['WARNING'] = 'Standalone ' + standalone + ' cannot "' + oslevel_cmd + '"'
          Log.log_warning('error while doing "' + oslevel_cmd + '" on "' + standalone + '"')
          Log.log_warning("stderr=#{stderr}")
          standalones_skipped[standalone] = standalone_hash
        end
      else
        standalone_hash['WARNING'] = 'Standalone ' + standalone + ' cannot "' + ping_cmd + '"'
        Log.log_warning('error while doing "' + ping_cmd + '"')
        Log.log_warning("ping_stderr=#{stderr}")
        standalones_skipped[standalone] = standalone_hash
      end
    end

    # Skipped
    Log.log_warning('standalones not kept="' + standalones_skipped.to_s + '"')
    # persist to yaml
    skipped_result_yml_file = ::File.join(Constants.output_dir,
                                          'facter',
                                          'standalones_skipped.yml')
    File.write(skipped_result_yml_file, standalones_skipped.to_yaml)
    Log.log_info('Refer to "' + skipped_result_yml_file + '" to have results of skipped "standalones" facter.')

    # Kept
    # persist to yaml
    kept_result_yml_file = ::File.join(Constants.output_dir,
                                       'facter',
                                       'standalones_kept.yml')
    File.write(kept_result_yml_file, standalones_kept.to_yaml)
    Log.log_info('Refer to "' + kept_result_yml_file + '" to have results of kept "standalones" facter.')
    standalones_kept
  end
end
