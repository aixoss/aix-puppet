require_relative './Constants.rb'
require 'fileutils'
require 'yaml'

module Automation
  module Lib
    # #########################################################################
    # Class Vios
    # #########################################################################
    class Vios

      # ########################################################################
      # name : check_input_viospair
      # param :input:viospair:array of two vios
      # param :output:kept:array of array of two strings
      # param :output:suppressed:array of array of two strings
      # return : 2 output params
      # description : checks 'viospair' array, if both vios are valid, then
      #   add 'viospair' into 'kept', otherwise add 'viospair' into 'suppressed'
      # ########################################################################
      def self.check_input_viospair(viospair,
          kept,
          suppressed)
        Log.log_debug('Into check_input_viospair viospair=' + viospair.to_s +
                          ' kept=' + kept.to_s +
                          ' suppressed=' + suppressed.to_s)
        #
        valid_vios = Facter.value(:vios)
        Log.log_info('valid_vios=' + valid_vios.to_s)
        valid_vios_keys = valid_vios.keys
        Log.log_info('valid_vios_keys=' + valid_vios_keys.to_s)
        b_suppressed = false
        viospair.each do |vios|
          if !vios.empty?
            Log.log_info('valid_vios_keys=' + valid_vios_keys.to_s + ' vios=' + vios + ' include=' + (valid_vios_keys.include?(vios)).to_s)
            unless valid_vios_keys.include?(vios)
              suppressed.push(viospair)
              Log.log_warning("vios \"#{vios}\" of the \"#{viospair}\" pair \
is not part of vios facter, and therefore viospair cannot be kept.")
              b_suppressed = true
              break
            end
          else
            Log.log_err("vios \"#{vios}\" of the \"#{viospair}\" pair \
is empty, and therefore viospair cannot be kept.")
            suppressed.push(viospair)
            b_suppressed = true
          end
        end
        unless b_suppressed
          Log.log_info("both vios of #{viospair}\" pair \
have been tested ok, and therefore viospair is kept.")
          kept.push(viospair)
        end
        Log.log_debug('Ending check_input_viospair suppressed=' + suppressed.to_s)
        Log.log_debug('Ending check_input_viospair kept=' + kept.to_s)
      end

      # ##################################################################
      # Check the /usr/sbin/vioshc.py script can be used
      # Return: 0 if success
      # Raise: ViosHealthCheckError in case of error
      # ##################################################################
      def self.check_vioshc
        Log.log_debug('check_vioshc')
        vioshc_file = '/usr/sbin/vioshc.py'

        unless ::File.exist?(vioshc_file)
          msg = "Error: Health check script file '#{vioshc_file}': not found"
          raise ViosHealthCheckError, msg
        end

        unless ::File.executable?(vioshc_file)
          msg = "Error: Health check script file '#{vioshc_file}' not executable"
          raise ViosHealthCheckError, msg
        end

        Log.log_debug('check_vioshc ok')
        return 0
      end

      # ##################################################################
      # Collect VIOS and Managed System UUIDs.
      #
      # This first method calls 'vioshc.py' script to collect
      #  UUIDs.
      # Return 0 if success
      # Raise ViosHealthCheckError in case of error
      # ##################################################################
      def self.vios_health_init(nim_vios,
          hmc_id,
          hmc_ip)
        Log.log_debug("vios_health_init: nim_vios='#{nim_vios}' hmc_id='#{hmc_id}', hmc_ip='#{hmc_ip}'")
        ret = 0

        # If info have been found already and persisted into yml file
        #  then it is not necessary to do that.
        vios_kept_and_init_file = ::File.join(Constants.output_dir,
                                              'facter',
                                              'vios_kept_and_init.yml')
        #
        b_missing_UUID = false
        #
        if File.exist?(vios_kept_and_init_file)
          nim_vios_init = YAML.load_file(vios_kept_and_init_file)
          nim_vios.keys.each do |vios_key|
            if !nim_vios_init[vios_key]['vios_uuid'].nil? &&
                !nim_vios_init[vios_key]['vios_uuid'].empty? &&
                !nim_vios_init[vios_key]['cec_uuid'].nil? &&
                !nim_vios_init[vios_key]['cec_uuid'].empty?
              Log.log_info("vios_health_init: nim_vios_init[vios_key]['vios_uuid']=#{nim_vios_init[vios_key]['vios_uuid']} \
nim_vios_init[vios_key]['cec_uuid']=#{nim_vios_init[vios_key]['cec_uuid']} ")
              nim_vios[vios_key]['vios_uuid'] = nim_vios_init[vios_key]['vios_uuid']
              nim_vios[vios_key]['cec_uuid'] = nim_vios_init[vios_key]['cec_uuid']
            else
              b_missing_UUID = true
              break
            end
          end
        else
          b_missing_UUID = true
        end


        if b_missing_UUID
          cmd_s = "/usr/sbin/vioshc.py -i #{hmc_ip} -l a"
          # add verbose
          cmd_s << "-v "
          Log.log_info("vios_health_init: calling command '#{cmd_s}' to retrieve vios_uuid and cec_uuid")

          Open3.popen3({'LANG' => 'C'}, cmd_s) do |_stdin, stdout, stderr, wait_thr|
            stderr.each_line do |line|
              # nothing is print on stderr so far but log anyway
              Log.log_err("[STDERR] #{line.chomp}")
            end
            unless wait_thr.value.success?
              stdout.each_line { |line| Log.log_info("[STDOUT] #{line.chomp}") }
              Log.log_err("vios_health_init: calling command '#{cmd_s}' to retrieve vios_uuid and cec_uuid")
              return 1
            end

            cec_uuid = ''
            cec_serial = ''
            managed_system_section = 0
            vios_section = 0

            # Parse the output and store the UUIDs
            stdout.each_line do |line|
              # remove any space before and after
              line.strip!
              Log.log_debug("[STDOUT] #{line.chomp}")
              if line.include?("ERROR") || line.include?("WARN")
                # Needed this because vioshc.py script does not prints error to stderr
                Log.log_warning("[WARNING] vios_health_init: (vioshc.py) script: '#{line.strip}'")
                next
              end

              # New managed system section
              if managed_system_section == 0
                if line =~ /(\w{8}-\w{4}-\w{4}-\w{4}-\w{12})\s+(\w{4}-\w{3}\*\w{7})/
                  Log.log_debug("vios_health_init: start of MS section")
                  managed_system_section = 1
                  cec_uuid = Regexp.last_match(1)
                  cec_serial = Regexp.last_match(2)
                  Log.log_debug("vios_health_init: found managed system: cec_uuid:'#{cec_uuid}' cec_serial:'#{cec_serial}'")
                  next
                else
                  next
                end
              else
                if vios_section == 0
                  if line =~ /^VIOS\s+Partition\sID$/
                    vios_section = 1
                    Log.log_debug("vios_health_init: start of VIOS section")
                    next
                  else
                    next
                  end
                else
                  if line =~ /^$/
                    Log.log_debug("vios_health_init: end of VIOS section")
                    Log.log_debug("vios_health_init: end of MS section")
                    managed_system_section = 0
                    vios_section = 0
                    cec_uuid = ""
                    cec_serial = ""
                    next
                  else
                    if line =~ /(\w{8}-\w{4}-\w{4}-\w{4}-\w{12})\s+(\w+)/
                      vios_uuid = Regexp.last_match(1)
                      vios_part_id = Regexp.last_match(2)
                      Log.log_debug('vios_uuid=' + vios_uuid + ' vios_part_id=' + vios_part_id)

                      # Retrieve the vios with the vios_part_id and the cec_serial value
                      # and store the UUIDs in the dictionaries
                      nim_vios.keys.each do |vios_key|
                        if nim_vios[vios_key]['mgmt_vios_id'] == vios_part_id &&
                            nim_vios[vios_key]['mgmt_cec_serial2'] == cec_serial
                          nim_vios[vios_key]['vios_uuid'] = vios_uuid
                          nim_vios[vios_key]['cec_uuid'] = cec_uuid
                          Log.log_info("vios_health_init: found matching vios #{vios_key}: vios_part_id='#{vios_part_id}' vios_uuid='#{vios_uuid}'")
                          break
                        end
                      end

                      next
                    else
                      next
                    end

                  end
                end
              end
            end
          end

          # persist to yaml result
          File.write(vios_kept_and_init_file, nim_vios.to_yaml)
          Log.log_info('Refer to "' + vios_kept_and_init_file + '" to have results of "vios_health_init".')
        else
          Log.log_info("vios_health_init: yaml was enough to retrieve vios_uuid and cec_uuid")
        end
        ret
      end

      # ##################################################################
      # Health assessment of the VIOSes targets to ensure they can support
      #   a rolling update operation.
      # This operation uses 'vioshc.py' script to evaluate the capacity
      #   of the pair of the VIOSes to support the rolling update operation:
      # Return: 0 if ok, 1 otherwise
      # ##################################################################
      def self.vios_health_check(nim_vios,
          hmc_ip,
          vios_list)
        Log.log_debug("vios_health_check: hmc_ip: #{hmc_ip} vios_list: #{vios_list}")
        ret = 0
        rate = 0

        cmd_s = "/usr/sbin/vioshc.py -i #{hmc_ip} -m #{nim_vios[vios_list[0]]['cec_uuid']} "
        vios_list.each do |vios|
          cmd_s << "-U #{nim_vios[vios]['vios_uuid']} "
        end
        # add verbose
        cmd_s << "-v "
        Log.log_info("vios_health_check: calling command '#{cmd_s}' to perform health check")

        Open3.popen3({'LANG' => 'C'}, cmd_s) do |_stdin, stdout, stderr, wait_thr|
          stderr.each_line do |line|
            Log.log_err("[STDERR] #{line.chomp}")
          end
          ret = 1 unless wait_thr.value.success?

          # Parse the output to get the "Pass rate"
          stdout.each_line do |line|
            Log.log_info("[STDOUT] #{line.chomp}")

            if line.include?("ERROR") || line.include?("WARN")
              # Need because vioshc.py script does not prints error to stderr
              Log.log_warning("Health check (vioshc.py) script: '#{line.strip}'")
            end
            next unless line =~ /Pass rate of/

            rate = Regexp.last_match(1).to_i if line =~ /Pass rate of (\d+)%/

            if ret == 0 && rate == 100
              Log.log_info("VIOSes #{vios_list.join('-')} can be updated")
            else
              Log.log_warning("VIOSes #{vios_list.join('-')} can NOT be updated: only #{rate}% of checks pass")
              ret = 1
            end
            break
          end
        end

        ret
      end

      # ########################################################################
      # name : check_vios_disk
      # param : in:vios:string
      # param : in:disk:string
      # return : 0 or 1 depending if the test is ok or not
      # description : check that the disk provided can be used to perform
      #   a alt_disk_copy operation on this vios
      #
      # The alternate disk needs to
      #  - exist,
      #  - be free, (not be part of a VG, either visible or invisble)
      #  - have enough space to copy the rootvg (size of rootvg os got and
      #   compared with disk size)
      # ########################################################################
      #
      #    NOT USED ANYMORE
      #
      # def self.check_vios_disk(vios, disk)
      #   Log.log_debug('check_vios_disk on ' + vios + ' for ' + disk)
      #   ret = 1
      #   #
      #   # check disk exists, is free and get its size
      #   size_candidate_disk = Vios.check_free_disk(vios, disk)
      #   if size_candidate_disk != 0
      #     # meaning this disk is free => go on
      #     # get rootvg size
      #     size_rootvg, size_used_rootvg = Vios.get_vg_size(vios, 'rootvg')
      #     Log.log_info('get_vg_size on ' + vios + ' for rootvg : ' +
      #                      size_rootvg.to_s + ' ' + size_used_rootvg.to_s)
      #     if size_used_rootvg.to_i != 0
      #       if size_used_rootvg.to_i > size_candidate_disk.to_i
      #         # meaning this candidate disk is ok
      #         ret = 0
      #       end
      #     end
      #   end
      #   Log.log_debug('check_vios_disk on ' + vios + ' for ' + disk + ' returning ' + ret.to_s)
      #   ret
      # end

      # ########################################################################
      # name : find_best_alt_disks
      # param : in:viospairs: array of viospairs, each viospair being an array
      #    of two vios names on which we may desire performing alt_disk_copy
      # param : in:force: yes or no. If set to yes, it indicates that
      #    altinst_rootvg (if it exists) can be removed and its disk reused.
      #    If set to no, existing altinst_rootvg is not touched.
      # return : array of viospairs, each viospair being an array of two arrays,
      #    this inside array contains three strings : name,pvid,size
      # description : for each vios in input parameter, find the best free disk
      #   to perform alt_fisk_copy, this disk needs to be free, be large enough
      #   to contain rootvg of vios, but the smaller one of all possible disks
      #   should be chosen.
      # ########################################################################
      def self.find_best_alt_disks(viospairs,
          force)
        Log.log_debug('find_best_alt_disks for each vios of ' + viospairs.to_s + ' force =' + force.to_s)
        viospairs_returned = []
        viospairs.each do |viospair|
          viospair_returned = []
          viospair.each do |vios|
            Log.log_info('Call to check_rootvg_mirror: ' + vios.to_s)
            alt_disk_to_reuse = []
            if force.to_s == 'yes'
              Log.log_info('Call to perform_alt_disk_find_and_remove: ' + vios.to_s)
              ret = Vios.perform_alt_disk_find_and_remove(vios, alt_disk_to_reuse)
              if ret == 0
                Log.log_info('There was a altinst_rootvg on ' + vios.to_s + ' which has been cleaned.')
              end
            end

            # If a previous disk was used as disk for alt_disk_copy
            #  we'll reuse it
            vios_returned = []
            if alt_disk_to_reuse.empty? or alt_disk_to_reuse.nil?
              Log.log_info('find_best_alt_disks on: ' + vios.to_s)
            size_rootvg, size_used_rootvg = Vios.get_vg_size(vios, 'rootvg')
            Log.log_info('find_best_alt_disks on: ' + vios + ' rootvg: ' +
                             size_rootvg.to_s + ' ' + size_used_rootvg.to_s)
              #
              if size_used_rootvg.to_i != 0
              remote_cmd1 = "/usr/ios/cli/ioscli lspv -free | /bin/grep -v NAME"
              remote_output1 = []
              remote_cmd_rc1 = Remote.c_rsh(vios, remote_cmd1, remote_output1)
              if remote_cmd_rc1 == 0
                added = 0
                if !remote_output1[0].nil? and !remote_output1[0].empty?
                  Log.log_debug('remote_output1[0]=' + remote_output1[0].to_s)
                  remote_output1_lines = remote_output1[0].split("\n")
                  Log.log_debug('remote_output1_lines=' + remote_output1_lines.to_s)
                  # As there might be several disks possible, in a first pass we
                  #  keep them into disks_kept, and in a second pass we'll select
                  #  smaller one
                  disks_kept = []
                  remote_output1_lines.each do |remote_output1_line|
                    Log.log_debug('remote_output_lines=' + remote_output1_line.to_s)
                    name_candidate_disk, pvid_candidate_disk, size_candidate_disk = remote_output1_line.split
                    Log.log_debug("name_candidate_disk= #{name_candidate_disk} \
pvid_candidate_disk=#{pvid_candidate_disk} \
size_candidate_disk=#{size_candidate_disk}")
                    if size_used_rootvg.to_i < size_candidate_disk.to_i
                      disks_kept.push([name_candidate_disk, size_candidate_disk])
                      added += 1
                    end
                  end
                  # If there was one or several disks kept
                  #  we keep only the smaller one
                  if added != 0
                    name_candidate_disk = ''
                    min = disks_kept[0][1]
                    disks_kept.each do |disk_kept|
                      if disk_kept[1].to_i <= min.to_i
                        name_candidate_disk = disk_kept[0]
                      end
                    end
                    vios_returned.push([vios, name_candidate_disk])
                  else
                    vios_returned.push([vios])
                  end
                else
                  vios_returned.push([vios])
                end
              end
              else
                vios_returned.push([vios])
                Log.log_err('find_best_alt_disks: no free disk')
              end
            else
              # We reuse disk which was previously used as disk for alt_disk_copy
              Log.log_info('find_best_alt_disks: reusing ' + alt_disk_to_reuse[0])
              vios_returned.push([vios, alt_disk_to_reuse[0]])
            end
            Log.log_debug("vios_returned=#{vios_returned}")
            unless vios_returned.empty?
              viospair_returned.push(vios_returned)
            end
          end
          unless viospair_returned.empty?
            viospairs_returned.push(viospair_returned)
          end
        end
        #
        Log.log_debug('find_best_alt_disks on: ' + viospairs.to_s + ' returning:' + viospairs_returned.to_s)
        viospairs_returned
      end

      # ########################################################################
      # name : check_free_disk
      # param : in:vios:string
      # param : in:disk:string
      # return : 0 or size depending if the test is ok or not
      # description : check that the disk provided can be used to perform
      #   a alt_disk_copy operation on this vios, it must be free, and return
      #   its size, if it is the case.
      # ########################################################################
      #
      #    NOT USED ANYMORE
      #
      # def self.check_free_disk(vios, disk)
      #   Log.log_debug('check_free_disk ' + disk + ' on ' + vios)
      #   ret = 0
      #   remote_cmd1 = "/usr/ios/cli/ioscli lspv -free | /bin/grep -w " + disk + " | /bin/awk '{print $3}'"
      #   remote_output1 = []
      #   remote_cmd_rc1 = Remote.c_rsh(vios, remote_cmd1, remote_output1)
      #   if remote_cmd_rc1 == 0
      #     if !remote_output1[0].nil? and !remote_output1[0].empty?
      #       # here is the remote command output parsing method
      #       cmd = "/bin/echo \"#{remote_output1[0]}\" | /bin/awk '{print $3}'"
      #       stdout, stderr, status = Open3.capture3(cmd)
      #       Log.log_debug("status=#{status}") unless status.nil?
      #       if status.success?
      #         if !stdout.nil? && !stdout.strip.empty?
      #           Log.log_debug("stdout=#{stdout}")
      #         end
      #         ret = stdout
      #       else
      #         if !stderr.nil? && !stderr.strip.empty?
      #           Log.log_err("stderr=#{stderr}")
      #         end
      #       end
      #     else
      #       Log.log_err('check_free_disk "' + disk + '" on "' + vios + '" : either does not exist, or is not free')
      #     end
      #   else
      #     Log.log_err('check_free_disk "' + disk + '" cannot be checked on "' + vios + '"')
      #   end
      #   Log.log_debug('check_free_disk "' + disk + '" on "' + vios + '" returning ' + ret.to_s)
      #   ret
      # end

      # ########################################################################
      # name : get_vg_size
      # param : in:vios:string
      # param : in:vg_name:string
      # return : [size1,size2]
      # description : returns the total and used vg sizes in megabytes
      # ########################################################################
      def self.get_vg_size(vios,
          vg_name)
        Log.log_debug('get_vg_size on ' + vios + ' for ' + vg_name)
        vg_size = 0
        used_size = 0
        remote_cmd1 = '/usr/ios/cli/ioscli lsvg ' + vg_name
        remote_output1 = []
        remote_cmd_rc1 = Remote.c_rsh(vios, remote_cmd1, remote_output1)
        if remote_cmd_rc1 == 0
          Log.log_debug('remote_output1[0] ' + remote_output1[0])
          # stdout is like:
          # parse lsvg output to get the size in megabytes:
          # VG STATE:      active      PP SIZE:   512 megabyte(s)
          # VG PERMISSION: read/write  TOTAL PPs: 558 (285696 megabytes)
          # MAX LVs:       256         FREE PPs:  495 (253440 megabytes)
          # LVs:           14          USED PPs:   63 (32256 megabytes)
          remote_output1[0].each_line do |line|
            Log.log_debug("[STDOUT] #{line.chomp}")
            line.chomp!
            if line =~ /.*TOTAL PPs:\s+\d+\s+\((\d+)\s+megabytes\).*/
              vg_size = Regexp.last_match(1).to_i
            elsif line =~ /.*USED PPs:\s+\d+\s+\((\d+)\s+megabytes\).*/
              used_size += Regexp.last_match(1).to_i
            elsif line =~ /.*PP SIZE:\s+(\d+)\s+megabyte\(s\).*/
              used_size += Regexp.last_match(1).to_i
            end
          end
        else
          Log.log_err("Failed to get Volume Group '#{vg_name}' size: on #{vios}")
        end
        if vg_size == 0 || used_size == 0
          Log.log_err("Failed to get Volume Group '#{vg_name}' size: TOTAL PPs=#{vg_size}, USED PPs+1=#{vg_size[1]} on #{vios}")
          [0, 0]
        else
          Log.log_info("VG '#{vg_name}' TOTAL PPs=#{vg_size} MB, USED PPs+1=#{used_size} MB")
          [vg_size, used_size]
        end
      end

      # ##################################################################
      # Run the NIM alt_disk_install command to launch
      #  the alternate copy operation on specified vios
      # Return: 0 if ok, 1 otherwise
      # ##################################################################
      def self.perform_alt_disk_install(vios,
          disk,
          set_bootlist = 'no',
          boot_client = 'no')
        Log.log_debug("perform_alt_disk_install: vios: #{vios} disk: #{disk}")
        ret = 0
        cmd = "/usr/sbin/nim -o alt_disk_install -a source=rootvg -a disk=#{disk} \
-a set_bootlist=#{set_bootlist} -a boot_client=#{boot_client} #{vios}"
        Log.log_debug("perform_alt_disk_install: '#{cmd}'")
        Open3.popen3({'LANG' => 'C'}, cmd) do |_stdin, stdout, stderr, wait_thr|
          stdout.each_line { |line| Log.log_debug("[STDOUT] #{line.chomp}") }
          stderr.each_line do |line|
            Log.log_err("[STDERR] #{line.chomp}")
            ret = 1
          end
          Log.log_debug("perform_alt_disk_install: #{wait_thr.value}") # Process::Status object
        end
        ret
      end

      # ##################################################################
      # Wait for the alternate disk copy operation to finish
      #
      # when alt_disk_install operation ends the NIM object state changes
      # from "a client is being prepared for alt_disk_install" or
      #      "alt_disk_install operation is being performed"
      # to   "ready for NIM operation"
      #
      # You might want a timeout of 30 minutes (count=90, sleep=20s), if
      # there is no progress in NIM operation "info" attribute for this
      #  duration, it can be considered as an error. Manual intervention
      #  is required in that case.
      #
      # Returns
      #    0   if the alt_disk_install operation ends with success
      #    1   if the alt_disk_install operation failed
      #    -1  if the alt_disk_install operation timed out
      # ##################################################################
      def self.wait_alt_disk_install(vios,
          check_count = 90,
          sleep_time = 20)
        nim_info_prev = '___' # this info should not appear in nim info attribute
        nim_info = ''
        count = 0
        wait_time = 0

        ret = 0

        cmd_s = "/usr/sbin/lsnim -Z -a Cstate -a info -a Cstate_result #{vios}"
        Log.log_info("wait_alt_disk_install: '#{cmd_s}'")

        while count <= check_count do
          sleep(sleep_time)
          wait_time += 20
          nim_cstate = ''
          nim_result = ''
          nim_info = ''

          Open3.popen3({'LANG' => 'C'}, cmd_s) do |_stdin, stdout, stderr, wait_thr|
            stderr.each_line do |line|
              Log.log_err("[STDERR] #{line.chomp}")
            end
            unless wait_thr.value.success?
              stdout.each_line { |line| Log.log_info("[STDOUT] #{line.chomp}") }
              Log.log_err("Failed to get the NIM state for vios '#{vios}', see above error!")
              ret = 1
            end

            if ret == 0
              stdout.each_line do |line|
                Log.log_debug("[STDOUT] #{line.chomp}")

                # info attribute (that appears in 3rd possition) can be empty. So stdout looks like:
                # #name:Cstate:info:Cstate_result:
                # <viosName>:ready for a NIM operation:success:  -> len=3
                # <viosName>:alt_disk_install operation is being performed:Creating logical volume alt_hd2.:success:  -> len=4
                # <viosName>:ready for a NIM operation:0505-126 alt_disk_install- target disk hdisk2 has a volume group assigned to it.:failure:  -> len=4
                nim_status = line.strip.split(':')
                if nim_status[0] != "#name"
                  Log.log_info("\033[2K\r#{nim_status[2]}")
                  Log.log_info("nim_status:#{nim_status}")
                else
                  next
                end

                nim_cstate = nim_status[1]
                if nim_status.length == 3 && (nim_status[2].downcase == "success" || nim_status[2].downcase == "failure")
                  nim_result = nim_status[2].downcase
                elsif nim_status.length > 3
                  nim_info = nim_status[2]
                  nim_result = nim_status[3].downcase
                else
                  Log.log_warning("[#{vios}] Unexpected output #{nim_status} for command '#{cmd_s}'")
                end

                if nim_cstate.downcase == "ready for a nim operation"
                  Log.log_info("NIM alt_disk_install operation on #{vios} ended with #{nim_result}")
                  unless nim_result == "success"
                    msg = "Failed to perform NIM alt_disk_install operation on #{vios}: #{nim_info}"
                    Log.log_err(msg)
                    return 1
                  end
                  Log.log_info("\033[2K\r")
                  return 0 # here the operation succeeded
                else
                  if nim_info_prev == nim_info
                    count += 1
                  else
                    nim_info_prev = nim_info unless nim_info.empty?
                    count = 0
                  end
                end
                if wait_time.modulo(60) == 0
                  msg = "Waiting for the NIM alt_disk_install on #{vios}, duration: #{wait_time / 60} minute(s)"
                  Log.log_info("\033[2K\r#{msg}")
                end
              end
            end
          end
        end # while count

        # Timed out before the end of alt_disk_install
        msg = "NIM alt_disk_install operation for #{vios} shows no progress in #{count * sleep_time / 60} minute(s): #{nim_info}"
        Log.log_err(msg)
        return -1
      end


      # ########################################################################
      # name : perform_alt_disk_find_and_remove
      # param : in:vios:string
      # param : out:used_alt_disk:string array containing in index 0 alt_disk
      #  to be reused
      # description : Perform the symmetric operation of the NIM
      #  alt_disk_install to remove and clean the alternate copy operation
      #  on specified vios
      # Return: 0 if ok, 1 otherwise
      # ########################################################################
      def self.perform_alt_disk_find_and_remove(vios,
          used_alt_disk)
        Log.log_debug('perform_alt_disk_find_and_remove on ' + vios)
        ret = 1

        Log.log_info('Is there any existing altinst_rootvg on ' + vios + '?')
        remote_cmd0 = '/usr/sbin/lspv | /bin/grep -w altinst_rootvg'
        remote_outputs0 = []
        remote_cmd_rc0 = Remote.c_rsh(vios, remote_cmd0, remote_outputs0)
        if remote_cmd_rc0 == 0
          if !remote_outputs0[0].nil? and !remote_outputs0[0].empty?
            Log.log_debug('remote_output0[0]=' + remote_outputs0[0].to_s)
            remote_outputs0.each do |remote_output0|
              Log.log_debug('remote_output0=' + remote_output0.to_s)
              alt_disk_name, _junk1, _junk2, active = remote_output0.split

              Log.log_debug('alt_disk_name=' + alt_disk_name)
              Log.log_debug('active=' + active.to_s)
              if active.nil? or active.empty?
                Log.log_info('There is one existing altinst_rootvg on ' + vios + ' and we need to varyonvg it')
                remote_cmd1 = '/usr/sbin/varyonvg altinst_rootvg'
                remote_output1 = []
                remote_cmd_rc1 = Remote.c_rsh(vios, remote_cmd1, remote_output1)
                Log.log_debug('remote_cmd_rc1=' + remote_cmd_rc1.to_s + ' remote_output1[0]=' + remote_output1[0])
                ret = Vios.perform_alt_disk_remove(vios, alt_disk_name)
              else
                Log.log_info('There is one existing altinst_rootvg on ' + vios + ' but we dont need to varyonvg it')
              end
              # check again
              remote_cmd2 = '/usr/sbin/lsvg altinst_rootvg'
              remote_output2 = []
              remote_cmd_rc2 = Remote.c_rsh(vios, remote_cmd2, remote_output2)
              if remote_cmd_rc2 == 0
                Log.log_info('There is an altinst_rootvg on ' + vios)
                # Meaning altinst_rootvg exists, we then need to remove it
                ret = Vios.perform_alt_disk_remove(vios, alt_disk_name)
                used_alt_disk[0] = alt_disk_name
              end
            end
          else
            Log.log_info('No altinst_rootvg on ' + vios)
          end
        else
          Log.log_info('No altinst_rootvg on ' + vios)
        end
        Log.log_debug('perform_alt_disk_find_and_remove on ' + vios + ' returning ' + ret.to_s)
        ret
      end

      # ##################################################################
      # name : perform_alt_disk_remove
      # param : in:vios:string
      # param : in:alt_disk:string
      # description : Perform the symmetric operation of the NIM
      #  alt_disk_install to remove and clean the alternate copy
      #  operation on specified vios
      # Return: 0 if ok, 1 otherwise
      # ##################################################################
      def self.perform_alt_disk_remove(vios,
          alt_disk)
        Log.log_debug('perform_alt_disk_remove: vios=' + vios + ' disk=' + alt_disk)

        ret = 0
        #
        Log.log_debug('Cleaning altinst_rootvg on ' + vios)
        cmd1 = '/usr/sbin/alt_rootvg_op -X altinst_rootvg'
        cmd1_output = ''
        remote_cmd1_rc = Remote.c_rsh(vios, cmd1, cmd1_output)
        #
        if remote_cmd1_rc == 0
          Log.log_info('Succeeded in removing altinst_rootvg on ' + vios)
        else
          ret = 1
          Log.log_err("#{cmd1_output[0]}")
          Log.log_err('Failed to remove altinst_rootvg on ' + vios)
        end
        #
        if ret == 0
          #
          Log.log_debug('Cleaning disk ' + alt_disk + ' on ' + vios)
          cmd2 = "/etc/chdev -a pv=clear -l #{alt_disk}; /usr/bin/dd if=/dev/zero of=/dev/#{alt_disk} seek=7 count=1 bs=512"
          cmd2_output = ''
          remote_cmd2_rc = Remote.c_rsh(vios, cmd2, cmd2_output)
          if remote_cmd2_rc == 0
            Log.log_debug("#{cmd2_output[0]}")
            Log.log_info('Succeeded in cleaning altinst_rootvg on ' + vios)
          else
            Log.log_err("#{cmd2_output[0]}")
            Log.log_err('Failed to clean altinst_rootvg on ' + vios)
            ret = 1
          end
        end
        #
        Log.log_info('perform_alt_disk_remove: done, returning ' + ret.to_s)
        ret
      end

      # ########################################################################
      # name : check_rootvg_mirror
      # param : in:vios:string
      # param : out:copies:hash
      # return : 0 or -1
      # description : check if the rootvg is mirrored and if it is the case,
      #  that the mirror is not on same disk that the original. It it were
      #  the case, we wouldn't be able to un-mirror the rootvg, although this
      #  operation is mandatory before performing al_disk_copy.
      # ########################################################################
      def self.check_rootvg_mirror(vios,
          copies)
        Log.log_debug('check_rootvg_mirror for vios of ' + vios.to_s)
        ret = 0
        hdisk_copy = {}
        copy_hdisk = {}
        nb_lp = 0
        # The lsvg -M command lists the physical disks that contain the various logical volumes.
        # lsvg -M rootvg command OK, check mirroring
        # lists all PV, LV, PP details of a vg (PVname:PPnum LVname: LPnum :Copynum)
        # hdisk4:453      hd1:101
        # hdisk4:454      hd1:102
        # hdisk4:257      hd10opt:1:1
        # hdisk4:258      hd10opt:2:1
        # hdisk4:512-639
        # hdisk8:255      hd1:99:2        stale
        # hdisk8:256      hd1:100:2       stale
        # hdisk8:257      hd10opt:1:2
        # hdisk8:258      hd10opt:2:2
        # ..
        # hdisk9:257      hd10opt:1:3
        remote_cmd1 = "/usr/sbin/lsvg -M rootvg"
        remote_output1 = []
        Log.log_debug('check_rootvg_mirror for vios of ' + vios.to_s)
        remote_cmd_rc1 = Remote.c_rsh(vios,
                                      remote_cmd1,
                                      remote_output1)
        #
        if remote_cmd_rc1 == 0
          if !remote_output1[0].nil? and !remote_output1[0].empty?
            #Log.log_debug('remote_output1[0]=' + remote_output1[0].to_s)
            remote_output1_lines = remote_output1[0].split("\n")
            #Log.log_debug('remote_output1_lines=' + remote_output1_lines.to_s)
            remote_output1_lines.each do |remote_output1_line|
              remote_output1_line.chomp!
              # Log.log_debug('remote_output_lines=' + remote_output1_line.to_s)
              if remote_output1_line.include? 'stale'
                Log.log_warning("#{vios} rootvg contains stale partitions")
                ret = 1
                break
              elsif remote_output1_line.strip =~ /^(\S+):\d+\s+\S+:\d+:(\d+)$/
                #  case: hdisk8:257 hd10opt:1:2
                hdisk = Regexp.last_match(1)
                copy = Regexp.last_match(2).to_i
              elsif remote_output1_line.strip =~ /^(\S+):\d+\s+\S+:\d+$/
                # case: hdisk8:258 hd10opt:2
                hdisk = Regexp.last_match(1)
                copy = 1
              else
                next
              end
              #
              nb_lp += 1 if copy == 1
              # Log.log_info('hdisk='+hdisk.to_s+' copy='+copy.to_s)
              # Log.log_info('hdisk_copy.key?(hdisk)='+hdisk_copy.key?(hdisk).to_s)
              if hdisk_copy.key?(hdisk)
                # Log.log_info('hdisk_copy.key?(hdisk)='+hdisk_copy.key?(hdisk).to_s)
                if hdisk_copy[hdisk] != copy
                  # Log.log_info('hdisk_copy[hdisk]='+hdisk_copy[hdisk].to_s)
                  Log.log_warning("#{vios} rootvg data structure is not compatible with a \
alt_disk_copy operation (2 copies on the same disk)")
                  ret = 1
                end
              else
                hdisk_copy[hdisk] = copy
                # Log.log_debug('check_rootvg_mirror hdisk_copy='+hdisk_copy.to_s)
                # Log.log_info('!copy_hdisk.key?(copy)='+(!copy_hdisk.key?(copy)).to_s)
                unless copy_hdisk.key?(copy)
                  # Log.log_info('copy_hdisk.value?(hdisk)='+ copy_hdisk.value?(hdisk).to_s)
                  if copy_hdisk.value?(hdisk)
                    Log.log_warning("#{vios} rootvg data structure is not compatible with a \
alt_disk_copy operation (1 copy spread on more than one disk)")
                    ret = 1
                  else
                    copy_hdisk[copy] = hdisk
                    # Log.log_debug('check_rootvg_mirror copy_hdisk='+copy_hdisk.to_s)
                  end
                end
              end
              #
              if ret == 1
                break
              end
            end
            # Log.log_debug('check_rootvg_mirror nb_lp='+nb_lp.to_s)
          end
        end
        #
        if ret == 0
          if copy_hdisk.keys.length > 1 and (copy_hdisk.keys.length != hdisk_copy.keys.length)
            Log.log_warning("The #{vios} rootvg is partially or completly mirrored but some "\
                    'LP copies are spread on several disks. This prevents the '\
                    'system from building an alternate rootvg disk copy')
            ret = 1
          else
            copies[0] = copy_hdisk
          end
        end
        #
        Log.log_debug('check_rootvg_mirror for vios of ' + vios.to_s + ' returning ' +
                          copies.to_s + ' ret=' + ret.to_s)
        ret
      end

      # ##################################################################
      #  Run NIM mirror command
      #  Return : 0 if success, 1 if failure, -1 if not done
      # ##################################################################
      def self.perform_mirror(vios,
          vg_name,
          copies)
        ret = -1
        nb_copies = copies.length
        if nb_copies > 0
          ret = 0
          copy_nb = nb_copies + 1
          Log.log_debug('Performing mirroring of rootvg on ' + vios)
          cmd1 = "/usr/sbin/mirrorvg -m -c #{copy_nb} #{vg_name} #{copies[0]} "
          cmd1 += copies[1] if nb_copies > 1
          cmd1 += ' 2>&1'
          remote_output1 = []
          Log.log_debug('Performing mirroring of rootvg on ' + vios + ':' + cmd1)
          remote_cmd1_rc = Remote.c_rsh(vios, cmd1, remote_output1)
          #
          if remote_cmd1_rc == 0
            Log.log_debug('remote_output1[0] ' + remote_output1[0])
            remote_output1[0].each_line do |line|
              line.chomp!
              Log.log_debug("[STDOUT] #{line.chomp}")
              ret = 1 if line.include? 'Failed to mirror the volume group'
            end
          else
            ret = 1
            msg = "Failed to mirror '#{vg_name}' on #{vios}, command \"#{cmd1}\" returns above error!"
            Log.log_err("[STDERR] #{msg}")
          end

          if ret == 1
            Log.log_err("Failed to mirror '#{vg_name}' on '#{vios}'")
          else
            Log.log_info("Mirror '#{vg_name}' on '#{vios}' successful.")
          end
        end
        ret
      end

      # ##################################################################
      #  Run NIM unmirror command
      # ##################################################################
      def self.perform_unmirror(vios,
          vg_name)
        ret = 0
        Log.log_debug('Performing un-mirroring of rootvg on ' + vios)
        cmd1 = "/usr/sbin/unmirrorvg #{vg_name} 2>&1 "
        remote_output1 = []
        Log.log_debug('Performing un-mirroring of rootvg on ' + vios + ':' + cmd1)
        remote_cmd1_rc = Remote.c_rsh(vios, cmd1, remote_output1)
        #
        if remote_cmd1_rc == 0
          Log.log_debug('remote_output1[0] ' + remote_output1[0])
          remote_output1[0].each_line do |line|
            line.chomp!
            Log.log_debug("[STDOUT] #{line.chomp}")
            ret = 0 if line.include? 'successfully un-mirrored'
          end
        else
          ret = 1
          msg = "Failed to un-mirror '#{vg_name}' on #{vios}, command \"#{cmd1}\" returns above error!"
          Log.log_err("[STDERR] #{msg}")
        end

        #
        if ret == 0
          Log.log_info("Unmirror '#{vg_name}' on '#{vios}' successful.")
        end
        ret
      end

      # ##################################################################
      # Check the SSP status of the VIOS tuple
      # Alternate disk copy can only be done when both VIOSes in the tuple
      #     refer to the same cluster and have the same SSP status
      #
      #    return  0 if OK
      #            1 else
      # ##################################################################
      #
      #    NOT YET USED
      #
      # def self.get_vios_ssp_status(nim_vios,
      #     vios_list,
      #     vios_key,
      #     targets_status)
      #   #
      #   ssp_name = ''
      #   vios_ssp_status = ''
      #   vios_name = ''
      #   err_label = 'FAILURE-SSP'
      #   cluster_found = false
      #
      #   vios_list.each do |vios|
      #     nim_vios[vios]['ssp_status'] = 'none'
      #   end
      #
      #   # Get the SSP status
      #   vios_list.each do |vios|
      #     #  vios = vios_list[0]
      #     cmd_s = "/usr/lpp/bos.sysmgt/nim/methods/c_rsh #{nim_vios[vios]['vios_ip']} \"/usr/ios/cli/ioscli cluster -list &&  /usr/ios/cli/ioscli cluster -status -fmt :\""
      #
      #     Log.log_debug("ssp_status: '#{cmd_s}'")
      #     Open3.popen3({'LANG' => 'C'}, cmd_s) do |_stdin, stdout, stderr, wait_thr|
      #       stderr.each_line do |line|
      #         Log.log_err("[STDERR] #{line.chomp}")
      #       end
      #       unless wait_thr.value.success?
      #         stdout.each_line { |line| Log.log_info("[STDOUT] #{line.chomp}") }
      #         msg = "Failed to get SSP status of #{vios_key}"
      #         Log.log_warning("[#{vios}] #{msg}")
      #         raise ViosCmdError, "Error: #{msg} on #{vios}, command \"#{cmd_s}\" returns above error!"
      #       end
      #
      #       # check that the VIOSes belong to the same cluster and have the same satus
      #       #                  or there is no SSP
      #       # stdout is like:
      #       # gdr_ssp3:OK:castor_gdr_vios3:8284-22A0221FD4BV:17:OK:OK
      #       # gdr_ssp3:OK:castor_gdr_vios2:8284-22A0221FD4BV:16:OK:OK
      #       #  or
      #       # Cluster does not exist.
      #       #
      #       stdout.each_line do |line|
      #         Log.log_debug("[STDOUT] #{line.chomp}")
      #         line.chomp!
      #         if line =~ /^Cluster does not exist.$/
      #           Log.log_debug("There is no cluster or the node #{vios} is DOWN")
      #           nim_vios[vios]['ssp_vios_status'] = "DOWN"
      #           if vios_list.length == 1
      #             return 0
      #           else
      #             next
      #           end
      #         end
      #
      #         cluster_found = true
      #         if line =~ /^(\S+):(\S+):(\S+):\S+:\S+:(\S+):.*/
      #           cur_ssp_name = Regexp.last_match(1)
      #           cur_ssp_satus = Regexp.last_match(2)
      #           cur_vios_name = Regexp.last_match(3)
      #           cur_vios_ssp_status = Regexp.last_match(4)
      #
      #           if vios_list.include?(cur_vios_name)
      #             nim_vios[cur_vios_name]['ssp_vios_status'] = cur_vios_ssp_status
      #             nim_vios[cur_vios_name]['ssp_name'] = cur_ssp_name
      #             # single VIOS case
      #             if vios_list.length == 1
      #               if cur_vios_ssp_status == "OK"
      #                 err_msg = "SSP is active for the single VIOS: #{cur_vios_name}. VIOS cannot be updated"
      #                 put_error(err_msg)
      #                 targets_status[vios_key] = err_label
      #                 return 1
      #               else
      #                 return 0
      #               end
      #             end
      #             # first VIOS in the pair
      #             if ssp_name == ""
      #               ssp_name = cur_ssp_name
      #               vios_name = cur_vios_name
      #               vios_ssp_status = cur_vios_ssp_status
      #               next
      #             end
      #
      #             # both VIOSes found
      #             if vios_ssp_status != cur_vios_ssp_status
      #               err_msg = "SSP status is not the same for the both VIOSes: (#{vios_key}). VIOSes cannot be updated"
      #               put_error(err_msg)
      #               targets_status[vios_key] = err_label
      #               return 1
      #             elsif ssp_name != cur_ssp_name && cur_vios_ssp_status == "OK"
      #               err_msg = "Both VIOSes: #{vios_key} does not belong to the same SSP. VIOSes cannot be updated"
      #               put_error(err_msg)
      #               targets_status[vios_key] = err_label
      #               return 1
      #             else
      #               return 0
      #             end
      #             break
      #           end
      #         end
      #       end
      #     end
      #   end
      #
      #   if cluster_found == true
      #     return 0
      #   elsif ssp_name == ''
      #     return 0
      #   else
      #     err_msg = 'Only one VIOS belongs to an SSP. VIOSes cannot be updated'
      #     put_error(err_msg)
      #     targets_status[vios_key] = err_label
      #     return 1
      #   end
      # end

      # ##################################################################
      # Stop/start the SSP for a VIOS
      #
      #    ret = 0 if OK
      #          1 else
      # ##################################################################
      #
      #    NOT YET USED
      #
      # def self.ssp_stop_start(vios_list,
      #     vios,
      #     nim_vios,
      #     action)
      #   # if action is start SSP,  find the first node running SSP
      #   node = vios
      #   if action == 'start'
      #     vios_list.each do |n|
      #       if nim_vios[n]['ssp_vios_status'] == "OK"
      #         node = n
      #         break
      #       end
      #     end
      #   end
      #   cmd_s = "/usr/lpp/bos.sysmgt/nim/methods/c_rsh #{nim_vios[node]['vios_ip']} \"/usr/sbin/clctrl -#{action} -n #{nim_vios[vios]['ssp_name']} -m #{vios}\""
      #
      #   Log.log_debug("ssp_stop_start: '#{cmd_s}'")
      #   Open3.popen3({'LANG' => 'C'}, cmd_s) do |_stdin, stdout, stderr, wait_thr|
      #     stderr.each_line do |line|
      #       Log.log_err("[STDERR] #{line.chomp}")
      #     end
      #     unless wait_thr.value.success?
      #       stdout.each_line { |line| Log.log_info("[STDOUT] #{line.chomp}") }
      #       msg = "Failed to #{action} cluster #{nim_vios[vios]['ssp_name']} on vios #{vios}"
      #       Log.log_warning(msg)
      #       raise ViosCmdError, "#{msg}, command: \"#{cmd_s}\" returns above error!"
      #     end
      #   end
      #
      #   nim_vios[vios]['ssp_vios_status'] = if action == 'stop'
      #                                         "DOWN"
      #                                       else
      #                                         "OK"
      #                                       end
      #   Log.log_info("#{action} cluster #{nim_vios[vios]['ssp_name']} on vios #{vios} succeed")
      #
      #   return 0
      # end

      # ############################
      #     E X C E P T I O N      #
      # ############################
      class ViosError < StandardError
      end
      #
      class ViosHealthCheckError < ViosError
      end
      #
      class ViosHealthCheckError1 < ViosError
      end
      #
      class ViosHealthCheckError2 < ViosError
      end
      #
      class ViosHealthCheckError3 < ViosError
      end
      #
      class NimHmcInfoError < StandardError
      end
    end
  end
end
