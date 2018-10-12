require_relative '../puppet_x/Automation/Lib/Constants.rb'
require_relative '../puppet_x/Automation/Lib/Log.rb'
require_relative '../puppet_x/Automation/Lib/Remote/c_rsh.rb'

# ##############################################################################
# name : 'vios' factor
# param : none
# return : hash of vios.
#  Two files are generated: "output/facter/vios_skipped.yml" and
#  "output/facter/vios_kept.yml" as result log.
# description : this factor builds a fact called 'vios' containing a
#  hash with vios names known by the NIM server as value.
# ##############################################################################
include Automation::Lib
include Automation::Lib::Remote
#
Facter.add('vios') do
  setcode do
    Log.log_info('Computing "vios" facter')

    # Retrieves from :applied_manifest facter list of vios used in manifests/init.pp
    applied_manifest = Facter.value(:applied_manifest)
    allvios = applied_manifest['vios']

    vios_kept = {}
    vios_skipped = {}

    if allvios.nil? or allvios.empty?
      Log.log_info('Not necessary to compute "vios" facter')
      vios_skipped['all_vios_skipped'] = {}
    else

      vios_str = Facter::Core::Execution.execute("/usr/sbin/lsnim -t vios | /bin/awk \
'NR==FNR{print $1;next}{print $1}' | /bin/awk 'FNR!=1{print l}{l=$0};END{ORS=\"\";print l}' ORS=' '")
      vios_array = vios_str.split(' ')
      #
      vios_array.each do |vios|
        vios_hash = {}
        oslevel = ''
        ioslevel = ''

        unless allvios.include? vios
          vios_hash['WARNING'] = 'VIOS ' + vios + ' is not used in "manifests/init.pp. Skipping"'
          vios_skipped[vios] = vios_hash
          next
        end

        remote_cmd_rc = Remote.c_rsh(vios, '/usr/bin/oslevel -s', oslevel)
        if remote_cmd_rc == 0
          vios_hash['oslevel'] = oslevel.strip
        end

        remote_cmd_rc = Remote.c_rsh(vios, '/usr/ios/cli/ioscli ioslevel', ioslevel)
        if remote_cmd_rc == 0
          vios_hash['ioslevel'] = ioslevel.strip
        end

        #### ping
        cmd = "/usr/sbin/ping -c1 -w5 #{vios}"
        stdout, stderr, status = Open3.capture3("#{cmd}")
        Log.log_debug("cmd   =#{cmd}")
        Log.log_debug("status=#{status}")
        if status.success?
          Log.log_debug("stdout=#{stdout}")

          ##### oslevel
          oslevel = ""
          remote_cmd_rc = Remote.c_rsh(vios, "/usr/bin/oslevel -s", oslevel)
          if remote_cmd_rc == 0
            vios_hash['oslevel'] = oslevel.strip

            full_facter = true
            if full_facter

              ##### /etc/niminfo
              niminfo_str = ""
              remote_cmd_rc = Remote.c_rsh(vios, "/bin/cat /etc/niminfo |\
 /bin/grep '=' | /bin/sed 's/export //g'", niminfo_str)
              # Log.log_debug("remote_cmd_rc   =#{remote_cmd_rc}")
              if remote_cmd_rc == 0
                niminfo_lines = niminfo_str.split("\n")
                niminfo_lines.each do |envvar|
                  key, val = envvar.split('=')
                  vios_hash[key] = val
                end

                ##### Cstate from lsnim -l
                lsnim_str = Facter::Core::Execution.execute("/usr/sbin/lsnim -l " + vios)
                # Log.log_debug("lsnim_str   =#{lsnim_str}")
                lsnim_lines = lsnim_str.split("\n")
                lsnim_lines.each do |lsnim_line|
                  # Log.log_debug("lsnim_line   =#{lsnim_line}")
                  if lsnim_line =~ /^\s+Cstate\s+=\s+(.*)$/
                    # Cstate
                    cstate = Regexp.last_match(1)
                    vios_hash['cstate'] = cstate
                  elsif lsnim_line =~ /^\s+mgmt_profile1\s+=\s+(.*)$/
                    # For VIOS store the management profile
                    match_mgmtprof = Regexp.last_match(1)
                    mgmt_elts = match_mgmtprof.split
                    if mgmt_elts.size == 3
                      vios_hash['mgmt_hmc_id'] = mgmt_elts[0]
                      vios_hash['mgmt_vios_id'] = mgmt_elts[1]
                      cec_serial_id = Facter::Core::Execution.execute('/usr/sbin/lsnim -a serial -Z ' + mgmt_elts[2] + '| /usr/bin/grep ' + mgmt_elts[2])
                      vios_hash['mgmt_cec_serial1'], vios_hash['mgmt_cec_serial2'] = cec_serial_id.split(":")
                    end
                  elsif lsnim_line =~ /^\s+if1\s+=\s+\S+\s+(\S+)\s+.*$/
                    # IP
                    vios_hash['vios_ip'] = Regexp.last_match(1)
                  end
                end

                # SSP cluster name
                remote_cmd1 = '/usr/ios/cli/ioscli lsdev -dev vioscluster0 -attr clustername'
                remote_output1 = []
                remote_cmd_rc1 = Remote.c_rsh(vios,
                                              remote_cmd1,
                                              remote_output1)
                #
                Log.log_debug('remote_output1[0]=' + remote_output1[0].to_s + ' remote_cmd_rc1=' + remote_cmd_rc1.to_s)
                #
                if remote_cmd_rc1 == 0
                  # Cluster exists on this VIOS
                  if !remote_output1[0].nil? and !remote_output1[0].empty?
                    remote_output1_lines = remote_output1[0].split("\n")
                    # Log.log_debug('remote_output1_lines=' + remote_output1_lines.to_s)
                    remote_output1_lines.each do |remote_output1_line|
                      remote_output1_line.chomp!
                      Log.log_debug('remote_output1_line=' + remote_output1_line.to_s)
                      if remote_output1_line =~ /value/
                        next
                      elsif remote_output1_line.empty?
                        next
                      else
                        cluster_name = remote_output1_line
                        vios_hash['SSP_CLUSTER_NAME'] = cluster_name
                      end
                    end
                  else
                    Log.log_debug('remote_output1[] empty')
                    vios_hash['SSP_CLUSTER_NAME'] = ''
                  end
                else
                  Log.log_warning('No SSP cluster on this "' + vios + '" vios, this is NOT an error, and above error message is NOT an error.')
                  vios_hash['SSP_CLUSTER_NAME'] = ''
                end

                # yeah, we keep it !
                # Log.log_debug(" vios_hash = #{vios_hash}")
                vios_kept[vios] = vios_hash
              else
                Log.log_err("error while doing c_rsh '/bin/cat /etc/niminfo' on " + vios)
                vios_skipped[vios] = vios_hash
              end
            end
          else
            Log.log_err("error while doing c_rsh '/usr/bin/oslevel -s' on " + vios)
            Log.log_err("stderr=#{stderr}")
            vios_skipped[vios] = vios_hash
          end
        else
          Log.log_err("error while doing '/usr/sbin/ping -c1 -w5 ' " + vios)
          Log.log_err("stderr=#{stderr}")
          vios_skipped[vios] = vios_hash
        end
      end
    end

    # Skipped
    Log.log_warning('vios not kept="' + vios_skipped.to_s + '"')
    # persist to yaml
    skipped_result_yml_file = ::File.join(Constants.output_dir,
                                          'facter',
                                          'vios_skipped.yml')
    File.write(skipped_result_yml_file, vios_skipped.to_yaml)
    Log.log_info('Refer to "' + skipped_result_yml_file + '" to have results of skipped "vios" facter.')

    # Kept
    # persist to yaml
    kept_result_yml_file = ::File.join(Constants.output_dir,
                                       'facter',
                                       'vios_kept.yml')
    File.write(kept_result_yml_file, vios_kept.to_yaml)
    Log.log_info('Refer to "' + kept_result_yml_file + '" to have results of kept "vios" facter.')
    vios_kept
  end
end
