# ##########################################################################
# name : debug_level factor
# param : none
# return : debug level
# description : to set debug level
# ##########################################################################
Facter.add('debug_level') do
  setcode do
    4
  end
end
