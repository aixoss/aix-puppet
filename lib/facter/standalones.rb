require_relative '../puppet_x/Automation/Lib/Log.rb'
require_relative '../puppet_x/Automation/Lib/Constants.rb'
require_relative '../puppet_x/Automation/Lib/Remote/c_rsh.rb'

# ##########################################################################
# name : standalones factor
# param : none
# return : hash of standalones
# description : this factor builds a fact called 'standalones' containing a hash with all
#   standalones names known by the NIM server as value
#   oslevel -s as values.
# ##########################################################################
include Automation::Lib
include Automation::Lib::Remote
# this is not possible
# # Error: Facter: error while resolving custom facts in
# #  /etc/puppet/modules/aixautomation/lib/facter/standalones.rb:
# #  wrong argument type Class (expected Module)
# include Automation::Lib::Log

Facter.add('standalones') do
  setcode do
    standalones = {}

    # /usr/sbin/lsnim -t standalone |
    #   /bin/awk 'NR==FNR{print $1;next}{print $1}' |
    #   /bin/awk 'FNR!=1{print l}{l=$0};END{ORS="";print l}' ORS=' '
    standalones_str = Facter::Core::Execution.execute("/usr/sbin/lsnim -t standalone | \
/bin/awk 'NR==FNR{print $1;next}{print $1}' | \
/bin/awk 'FNR!=1{print l}{l=$0};END{ORS=\"\";print l}' ORS=' '")
    standalones_array = standalones_str.split(' ')

    #
    standalones_array.each do |standalone|
      standalone_hash = {}
      # To shorten demo, only keep quimby01 to quimby04
      # if standalone != "quimby01" && standalone != "quimby02"
      #  && standalone != "quimby03" \
      #  && standalone != "quimby04" && standalone != "quimby05" \
      #  && standalone != "quimby07" && standalone != "quimby08" \
      #  && standalone != "quimby09" && standalone != "quimby11"  \
      #  && standalone != "quimby12"
      #  Log.log_info("Please note, to shorten demo "+standalone+"
      #     standalone is not kept.")
      #  next
      # end

      # # To shorten demo, skipquimby10
      if standalone != 'quimby07'
        Log.log_info('Please note, to shorten demo ' + standalone +
                         ' standalone is not kept.')
        next
      end

      #### ping
      cmd = "/usr/sbin/ping -c1 -w5 #{standalone}"
      stdout, stderr, status = Open3.capture3(cmd.to_s)
      Log.log_debug("cmd   =#{cmd}")
      Log.log_debug("status=#{status}")
      if status.success?
        Log.log_debug("stdout=#{stdout}")
        ##### oslevel
        oslevel = ''
        returned = Automation::Lib::Remote.c_rsh(standalone,
                                                 '/usr/bin/oslevel -s', oslevel)
        if returned.success?
          standalone_hash['oslevel'] = oslevel.strip

          full_facter = true
          if full_facter
            # #### /etc/niminfo
            niminfo_str = ''
            returned = Automation::Lib::Remote.c_rsh(standalone,
                                                     "/bin/cat /etc/niminfo |\
 /bin/grep '=' | /bin/sed 's/export //g'", niminfo_str)
            if returned.success?
              # Log.log_debug('niminfo_str=' + niminfo_str.to_s)
              niminfo_lines = niminfo_str.split("\n")
              # Log.log_debug('niminfo_lines=' + niminfo_lines.to_s)
              niminfo_lines.each do |envvar|
                key, val = envvar.split('=')
                standalone_hash[key] = val
                # Log.log_debug('standalone_hash[' + key + ']=' + val)
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
                # NEEDS TO BE TESTED AGAIN
                if cstate == 'ready for a NIM operation'
                  keep_it = true
                end
              end
              if keep_it
                # yeah, we keep it ! ping ok, lsnim ok, crsh ok, cstate ok
                standalones[standalone] = standalone_hash
                # Log.log_debug('standalones[' + standalone + ']=' + standalone_hash.to_s)
              else
                Log.log_err('error on Cstate for : ' + standalone)
              end
            else
              Log.log_err("error while doing c_rsh '/bin/cat /etc/niminfo' on " +
                              standalone)
            end
          else
            # yeah, we keep it ! ping ok, lsnim ok, crsh ok, cstate ok
            standalones[standalone] = standalone_hash
          end
        else
          Log.log_err("error while doing c_rsh '/usr/bin/oslevel -s' on " +
                          standalone)
          Log.log_err("stderr=#{stderr}")
        end
      else
        Log.log_err("error while doing '/usr/sbin/ping -c1 -w5 ' " +
                        standalone)
        Log.log_err("stderr=#{stderr}")
      end
    end

    # persist to yaml
    result_yml_file = 'standalones.yml'
    File.write(result_yml_file, standalones.to_yaml)
    Log.log_debug('Refer to "'+result_yml_file+'" to have results of "standalones" facter.')
    standalones
  end
end
