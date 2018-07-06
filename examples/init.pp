#
# The baseline for module testing used by Puppet Inc. is that each manifest
#  should have a corresponding test manifest that declares that class or defined
#  type.
#
# Manifest init.pp contains all declarations to be applied on your systems.
# You can launch it, by using:
#    puppet apply --noop --modulepath=/etc/puppetlabs/code/environments/production/modules -e "include aixautomation"
#  to check for compilation errors and view a log of events
# Or by fully applying the manifest in a real environment, by using:
#    puppet apply --debug --modulepath=/etc/puppetlabs/code/environments/production/modules -e "include aixautomation"
#  to apply manifest and run it.
# Or by using:
#    puppet apply --debug \
#          --logdest=/etc/puppetlabs/code/environments/production/modules/aixautomation/output/logs/Puppet.log \
#          --modulepath=/etc/puppetlabs/code/environments/production/modules -e "include aixautomation"
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
  # This rule is the one provided into manifest/init.pp by default,
  #  to perform only a suma preview.
  # Facters are launched, then manifests/init.pp custom types validation
  #  is performed and tehen executed: suma preview is launched with below
  #  parameteres.
class aixautomation {
  download { "test suma-preview":
    ensure => present,
    type => "SP",
    root => "/tmp",
    from => "7200-01-02-1717",
    to => "7200-01-03-1720",
    to_step => "preview",
  }
}
*
/*
class aixautomation {
  # This rule allows to perform download through suma provider
  #  to get update of 7100-03-07-1614 SP into /export/extra/puppet/suma
  #  for a system which is currently in 7100-03
  # lpp_source created is named : PAA_SP_7100-03_7100-03-07-1614
  #  and this same name needs to be used to perform update
  # "/export/extra/puppet/suma" is the root directory of download
  #  It should be an ad hoc file system dedicated to download
  #   data, keep this file system separated from the system to prevent
  #   saturation.
  download { "my_download_3":
    provider   => suma,
    ensure     => present,
    name       => "my_download_3",
    type       => "SP",
    root       => "/export/extra/puppet/suma",
    from       => "7100-03",
    to         => "7100-03-07-1614",
    lpp_source => "PAA_SP_7100-03_7100-03-07-1614",
  }
  # This rule allows to perform download through suma provider
  #  to get update of 7100-04 TL into /export/extra/puppet/suma
  #  for a system which is currently in 7100-03
  # lpp_source created is named : PAA_TM_7100-03_7100-04
  #  and this same name needs to be used to perform update
  # "/export/extra/puppet/suma" is the root directory of download
  #  It should be an ad hoc file system dedicated to download
  #   data, keep this file system separated from the system to prevent
  #   saturation.
  download { "my_download_4":
    provider   => suma,
    ensure     => present,
    name       => "my_download_4",
    type       => "TL",
    root       => "/export/extra/puppet/suma",
    from       => "7100-03",
    to         => "7100-04",
  }
  # This rule allows to perform download through suma provider
  #  to get update of 7100-05 TL into /export/extra/puppet/suma
  #  for a system which is currently in 7100-03
  # lpp_source created is named : PAA_TM_7100-03_7100-05
  #  and this same name needs to be used to perform update
  # "/export/extra/puppet/suma" is the root directory of download
  #  It should be an ad hoc file system dedicated to download
  #   data, keep this file system separated from the system to prevent
  #   saturation.
  download { "my_download_5":
    provider   => suma,
    ensure     => present,
    name       => "my_download_5",
    type       => "TL",
    root       => "/export/extra/puppet/suma",
    from       => "7100-03",
    to         => "7100-05",
  }
  # This rule allows to perform cleaning of download directory
  #  "/export/extra/puppet/suma/lpp_dource/SP/7100-037100-03-07-1614"
  #  Moreover the NIM resource "PAA_SP_7100-03_7100-03-07-1614" is removed.
  download { "my_clean_3":
    provider   => suma,
    ensure     => absent,
    name       => "my_clean_3",
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
  # This rule allows to perform update through nimpush provider
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
class aixautomation {
  # This rule allows to perform preview update through nimpush provider
  #  of the clio3 system so that its update to the 7100-03-07-1614 SP
  #  is previewed.
  # The lpp_source is the one built by download rule
  #  PAA_SP_7100-03-05-1524_7100-03-07-1614
  patchmngt { "update clio3 to PAA_SP_7100-03-05-1524_7100-03-07-1614":
    provider   => nimpush,
    ensure     => present,
    name       => "update clio3 to PAA_SP_7100-03-05-1524_7100-03-07-1614",
    action     => "update",
    targets    => "clio3",
    sync       => "yes",
    lpp_source => "PAA_SP_7100-03-05-1524_7100-03-07-1614",
    preview    => "yes",
  }
*/
/*
class aixautomation {
  # This rule allows to perform update in apply mode through nimpush provider
  #  of the clio3 system so that it is updated to the 7100-03-07-1614 SP.
  # The lpp_source is the one built by download rule
  #  PAA_SP_7100-03-05-1524_7100-03-07-1614
  patchmngt { "update clio3 to PAA_SP_7100-03-05-1524_7100-03-07-1614":
    provider   => nimpush,
    ensure     => present,
    name       => "update clio3 to PAA_SP_7100-03-05-1524_7100-03-07-1614",
    action     => "update",
    targets    => "clio3",
    sync       => "yes",
    lpp_source => "PAA_SP_7100-03-05-1524_7100-03-07-1614",
    preview    => "no",
  }
  # This rule allows to perform reject of all updates (which were applied only)
  #  through nimpush provider of the clio3 system so that it comes back to its
  #  previous level : 7100-03-05-1524 SP
  # Please note that to be able to reject, you must set 'ensure' to 'absent'.
  patchmngt { "reject updates of clio3":
    provider   => nimpush,
    ensure     => absent,
    name       => "reject updates of clio3",
    action     => "update",
    targets    => "clio3",
    sync       => "yes",
    mode       => "reject",
  }
*/
/*
class aixautomation {
  # This rule allows to perform update in apply mode through nimpush provider
  #  of the clio4 system so that it is updated to the 7100-03-08-1642 SP.
  # The lpp_source is the one built by download rule
  #  PAA_SP_7100-03-05-1524_7100-03-08-1642
  patchmngt { "update clio4 to PAA_SP_7100-03-05-1524_7100-03-08-1642":
    provider   => nimpush,
    ensure     => present,
    name       => "update clio4 to PAA_SP_7100-03-05-1524_7100-03-08-1642",
    action     => "update",
    targets    => "clio4",
    sync       => "yes",
    lpp_source => "PAA_SP_7100-03-05-1524_7100-03-08-1642",
  }
  # This rule allows to perform commit of all updates (which were applied only)
  #  through nimpush provider of the clio4 system so that it keeps its level
  #  previous level : 7100-03-05-1524 SP
  patchmngt { "commit updates of clio4":
    provider   => nimpush,
    ensure     => present,
    name       => "commit updates of clio4",
    action     => "update",
    targets    => "clio4",
    sync       => "yes",
    mode       => "commit",
  }
*/
/*
 3. Samples of efix installation
*/
/*
class aixautomation {
  # This rule allows to install iFix through flrtvc provider,
  #  on the quimby01 and quimby02 systems so that they are fixed as best as possible.
  # Setting ensure to 'present'
  # List of appropriate eFix is computed for each system, and then applied.
  # Possible steps are : runFlrtvc, parseFlrtvc, downloadFixes, checkFixes, buildResource
  #  installResource.
  # Clean is by default set to 'yes', but if you want to spare time and reuse previous
  #  result of computation for each step, you can set force to 'no'.
  # "/export/extra/puppet/flrtvc" is suggested as root directory of download
  #  It should be an ad hoc file system dedicated to download
  #   data, keep this file system separated from the system so prevent
  #   saturation
  fix { "efix_install_1":
    provider => flrtvc,
    name     => "efix_install_1",
    ensure   => present,
    to_step  => "installResource",
    targets  => "quimby01 quimby02",
    force    => "no",
    root     => "/export/extra/puppet/flrtvc",
  }
*/
/*
class aixautomation {
  # This rule allows to remove iFix through flrtvc provider
  #  from the quimby03 and quimby04 systems
  # Setting ensure to 'absent'
  # All iFix are removed.
  fix { "efix_install_2":
    provider => flrtvc,
    name     => "efix_install_2",
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
  # This rule allows to install lpp_source through nimpush provider,
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
  # This rule allows to remove lpp_source through nimpush provider,
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
/*
5. Samples with all steps together

 This sample shows how to update one LPAR 'castor8' to the last 721 SP, and
  install all efixes.
*/
/*
class aixautomation {
  download { "test PAA_SP_7200-01-02-1717_7200-01-03-1720":
    provider => suma,
    ensure => present,
    name => "test PAA_SP_7200-01-02-1717_7200-01-03-1720",
    type => "SP",
    root => "/exports/extra/test-puppet/suma",
    from => "7200-01-02-1717",
    to => "7200-01-03-1720",
    to_step => "download",
    lpp_source => "PAA_SP_7200-01-02-1717_7200-01-03-1720",
  }
  patchmngt { "update castor8 to 7200-01-03-1720":
    provider   => nimpush,
    ensure     => present,
    name       => "update castor8 to 7200-01-03-1720",
    action     => "update",
    targets    => "castor8",
    sync       => "yes",
    lpp_source => "PAA_SP_7200-01-02-1717_7200-01-03-1720",
  }
  fix { "efix_install":
    provider => flrtvc,
    name     => "efix_install",
    ensure   => present,
    to_step  => "installResource",
    targets  => "castor8",
    force    => "yes",
    root     => "/exports/extra/test-puppet/flrtvc",
  }
}
*/