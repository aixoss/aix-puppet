require_relative '../puppet_x/Automation/Lib/Constants.rb'
require_relative '../puppet_x/Automation/Lib/Log.rb'
require_relative '../puppet_x/Automation/Lib/Remote/c_rsh.rb'

# ##############################################################################
# name : 'hmc' factor
# param : none
# return : hash of hmc.
#  One file is generated: "output/facter/hmc.yml" as result log.
# description : this factor builds a fact called 'hmc' containing a
#  hash with hmc names known by the NIM server as value and a hash of
#  hmc characteristics as values.
# ##############################################################################
include Automation::Lib
include Automation::Lib::Remote

#
Facter.add('hmc') do
  setcode do
    Log.log_info('Computing "hmc" facter')

    hmc_hash = {}

    cmd = "/usr/sbin/lsnim -t hmc -l"
    Log.log_info("cmd: #{cmd}")
    Open3.popen3({'LANG' => 'C'}, cmd) do |_stdin, stdout, stderr, wait_thr|
      stderr.each_line do |line|
        Log.log_err("[STDERR] #{line.chomp}")
      end
      unless wait_thr.value.success?
        stdout.each_line {|line| Log.log_err("[STDOUT] #{line.chomp}")}
        raise NimHmcInfoError, "Error: Command \"#{cmd}\" returns above error!"
      end

      #
      hmc_key = ''
      stdout.each_line do |line|
        Log.log_debug("[STDOUT] #{line.chomp}")
        # HMC name
        if line =~ /^(\S+):/
          hmc_key = Regexp.last_match(1)
          hmc_hash[hmc_key] = {}
          # Log.log_info('hmc_hash1='+hmc_hash.to_s)
          next
        end
        # Cstate
        if line =~ /^\s+Cstate\s+=\s+(.*)$/
          # Log.log_info('hmc_hash2='+hmc_hash.to_s)
          cstate = Regexp.last_match(1)
          # Log.log_info('cstate='+cstate.to_s)
          hmc_hash[hmc_key]['cstate'] = cstate
          # Log.log_info('hmc_hash2='+hmc_hash.to_s)
          next
        end
        # passwd_file
        if line =~ /^\s+passwd_file\s+=\s+(.*)$/
          # Log.log_info('hmc_hash3='+hmc_hash.to_s)
          passwd_file = Regexp.last_match(1)
          # Log.log_info('passwd_file='+passwd_file.to_s)
          hmc_hash[hmc_key]['passwd_file'] = passwd_file
          # Log.log_info('hmc_hash3='+hmc_hash.to_s)
          next
        end
        # login
        if line =~ /^\s+login\s+=\s+(.*)$/
          # Log.log_info('hmc_hash4='+hmc_hash.to_s)
          login = Regexp.last_match(1)
          # Log.log_info('login='+login.to_s)
          hmc_hash[hmc_key]['login'] = login
          # Log.log_info('hmc_hash4='+hmc_hash.to_s)
          next
        end
        # ip
        if line =~ /^\s+if1\s*=\s*\S+\s*(\S*)\s*.*$/
          # Log.log_info('hmc_hash5='+hmc_hash.to_s)
          ip = Regexp.last_match(1)
          # Log.log_info('ip='+ip.to_s)
          hmc_hash[hmc_key]['ip'] = ip
          # Log.log_info('hmc_hash5='+hmc_hash.to_s)
          next
        end
      end
    end

    # persist to yaml
    hmc_yml_file = ::File.join(Constants.output_dir,
                               'facter',
                               'hmc.yml')
    File.write(hmc_yml_file, hmc_hash.to_yaml)
    Log.log_info('Refer to "' + hmc_yml_file + '" to have results of "hmc" facter.')
    hmc_hash
  end
end