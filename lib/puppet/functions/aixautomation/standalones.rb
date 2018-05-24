# ##########################################################################
# name : aixautomation::standalones
# param : none
# return : list of standalones
# description : based on :standalones fact, the string returned is a
#  coma-separated list of standalones
# ##########################################################################
Puppet::Functions.create_function(:'aixautomation::standalones') do
  def standalones
    standalones_str = ''
    Facter.value(:standalones).each do |standalone, _oslevel|
      standalones_str = if standalones_str.empty?
                          standalone
                        else
                          standalones_str + ',' + standalone
                        end
    end
    standalones_str
  end
end
