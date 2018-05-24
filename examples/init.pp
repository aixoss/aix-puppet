#
# The baseline for module testing used by Puppet Inc. is that each manifest
#  should have a corresponding test manifest that declares that class or defined
#  type.
#
# Manifest init.pp contains all declarations to be applied on your systems.
# You can launch it, by using:
#    puppet apply --noop --modulepath=/etc/puppet/modules -e "include aixautomation"
#  to check for compilation errors and view a log of events
# Or by fully applying the manifest in a real environment, by using:
#    puppet apply --debug --modulepath=/etc/puppet/modules -e "include aixautomation"
#  to apply manifest and run it.
# Or by using:
#    puppet apply --debug --logdest=/tmp/Puppet.log \
#                 --modulepath=/etc/puppet/modules -e "include aixautomation"
#  to apply manifest and run it, keeping all logs into a file
#
# This examples.init.pp contains several samples of declarations with complete explanations
#  so that you can start from these samples and experiment.
#
# You can as well learn more about module testing here:
#  https://docs.puppet.com/guides/tests_smoke.html
#

/*
  1. Samples of downloads
*/
/*
class aixautomation {
  # This rule allows to perform download thru suma provider
  #  to get update of 7100-03 TL into /export/extra/puppet/suma
  #  for a system which is currently in 7100-01
  # lpp_source created is named : PAA_TL_7100-01_7100-03
  #  and this same name needs to be used to perform update
  # "/export/extra/puppet/suma" is suggested as root directory of download
  #  It should be an ad hoc file system dedicated to download
  #   data, keep this file system separated from the system so prevent
  #   saturation
  download { "my_download_1":
    provider   => suma,
    ensure     => present,
    name       => "my_download_1",
    type       => "TL",
    root       => "/export/extra/puppet/suma",
    from       => "7100-01",
    to         => "7100-03",
    lpp_source => "PAA_TL_7100-01_7100-03",
  }
}
*/
/*
class aixautomation {
  # This rule allows to perform download thru suma provider
  #  to get update of 7100-03-07-1614 SP into /export/extra/puppet/suma
  #  for a system which is currently in 7100-03
  # lpp_source created is named : PAA_SP_7100-03_7100-03-07-1614
  #  and this same name needs to be used to perform update
  # "/export/extra/puppet/suma" is suggested as root directory of download
  #  It should be an ad hoc file system dedicated to download
  #   data, keep this file system separated from the system so prevent
  #   saturation
  download { "my_download_2":
    provider   => suma,
    ensure     => present,
    name       => "my_download_2",
    type       => "SP",
    root       => "/export/extra/puppet/suma",
    from       => "7100-03",
    to         => "7100-03-07-1614",
    lpp_source => "PAA_SP_7100-03_7100-03-07-1614",
  }
}
*/

/*
 2. Samples of update
*/
/*
class aixautomation {
  # This rule allows to perform update thru nimpush provider
  #  of the quimby07 system so that it is updated to the
  #  7100-03-07-1614 SP
  # The lpp_source is the one built by download rule
  #  PAA_SP_7100-03_7100-03-07-1614
  patchmngt { "update quimby07 to 7100-03-07-1614":
    provider   => nimpush,
    ensure     => present,
    name       => "update quimby07 to 7100-03-07-1614",
    action     => "update",
    targets    => "quimby07",
    sync       => "yes",
    lpp_source => "PAA_SP_7100-03_7100-03-07-1614",
  }
}
*/

/*
 3. Samples of update
*/
/*
class aixautomation {
  # This rule allows to install iFix thru flrtvc provider,
  #  on the quimby01 and quimby02 systems so that they are fixed as best as possible.
  # Setting ensure to 'present'
  # List of appropriate eFix is computed for each system, and then applied.
  # Possible steps are : runFlrtvc, parseFlrtvc, downloadFixes, checkFixes, buildResource
  #  installResource.
  # Clean is by default set to 'yes', but if you want to spare time and reuse previous
  #  result of computation for each step, you can set clean to 'no'.
  # "/export/extra/puppet/suma" is suggested as root directory of download
  #  It should be an ad hoc file system dedicated to download
  #   data, keep this file system separated from the system so prevent
  #   saturation
  fix { "ifix_install_1":
    provider => flrtvc,
    name     => "ifix_install_1",
    ensure   => present,
    to_step  => "installResource",
    targets  => "quimby01 quimby02",
    clean => "no",
    root     => "/export/extra/puppet/flrtvc",
  }
*/
/*
class aixautomation {
  # This rule allows to remove iFix thru flrtvc provider
  #  from the quimby03 and quimby04 systems
  # Setting ensure to 'absent'
  # All iFix are removed.
  fix { "ifix_install_2":
    provider => flrtvc,
    name     => "ifix_install_2",
    ensure   => absent,
    targets  => "quimby03 quimby04",
  }
}
*/


/*
 4. Samples of install and remove
*/
/*
class aixautomation {
  # This rule allows to install lpp_source thru nimpush provider,
  #  on the quimby01 and quimby02 systems.
  # Setting ensure to 'present'
  # Action to be done is 'install'.
  # LppSource to be installed : dos2unix, a very simple lpp_source containing
  #  only one lpp "dos2unix.bff" as a sample.
  patchmngt { "dos2unix_install":
    provider   => nimpush,
    ensure     => present,
    name       => "dos2unix_install",
    action     => "install",
    lpp_source => "dos2unix",
    targets    => "quimby01, quimby02",
    sync       => "yes",
  }
}
*/
/*
class aixautomation {
  # This rule allows to remove lpp_source thru nimpush provider,
  #  on the quimby01 and quimby02 systems.
  # Setting ensure to 'absent'
  # Action to be done is 'install'.
  # LppSource to be removed : dos2unix, the one which was installed above.
  patchmngt { "dos2unix_remove":
    provider   => nimpush,
    ensure     => present,
    name       => "dos2unix_remove",
    action     => "install",
    lpp_source => "dos2unix",
    targets    => "quimby01, quimby02",
    sync       => "yes",
  }
}
*/