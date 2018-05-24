# ##########################################################################
# name : aixautomation::get_os_level
# param : standalone
# return : oslevel -s of a standalone
# description : based on :standalones fact, the string returned is
#   the /usr/bin/oslevel -s of the standalone
# ##########################################################################
Puppet::Functions.create_function(:'aixautomation::get_os_level') do
  def get_os_level(standalone)
    Facter.value(:standalones)[standalone]
  end
end
