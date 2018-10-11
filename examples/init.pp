#
# Manifest init.pp contains all declarations to be applied on your systems.
# You can check for compilation errors and view a log of events, by using:
#    puppet apply --noop --modulepath=/etc/puppetlabs/code/environments/production/modules -e "include aixautomation"
# Or to really apply manifest and run it in a real environment, by using:
#    puppet apply --debug --modulepath=/etc/puppetlabs/code/environments/production/modules -e "include aixautomation"
# Or to really apply manifest and run it in a real environment, keeping all logs into a file, by using:
#    puppet apply --debug \
#          --logdest=/etc/puppetlabs/code/environments/production/modules/aixautomation/output/logs/Puppet.log \
#          --modulepath=/etc/puppetlabs/code/environments/production/modules -e "include aixautomation"
#
# This examples/init.pp contains several samples of declarations (or rules)
#  with complete explanations so that you can start from these samples and
#  experiment.
#
# You can as well learn more about module testing here:
#  https://docs.puppet.com/guides/tests_smoke.html
#
/*
  I. Samples of AIX updates
   Using 'download', 'fix', and patchmngt' custom types.
*/
/*
  I.1. Samples of suma-downloads
   Declaration used here is 'download'.
*/
/*
  # This declaration is the one provided into manifests/init.pp by default,
  #  to perform only a suma-download preview.
  # Facters are launched, then manifests/init.pp custom types validation
  #  are performed and then executed: suma preview is launched with below
  #  attributes.
class aixautomation {
  download { "test suma-preview":
    ensure => present,
    type => "SP",
    root => "/tmp",
    from => "7200-01",
    to => "7200-01-03-1720",
    to_step => "preview",
  }
}
*
/*
class aixautomation {
  # This declaration allows to perform suma-download through suma provider
  #  to get update of 7100-03-07-1614 SP into /export/extra/puppet/suma
  #  for a system which is currently in 7100-03.
  # lpp_source created is named : PAA_SP_7100-03_7100-03-07-1614
  #  (PAA prefix stands for Puppet AixAutomation)
  #  and this same name needs to be used to perform update, by using
  #  'patchmngt' declaration.
  # "/export/extra/puppet/suma" is the root directory of download.
  # It should be an ad-hoc file system dedicated to download amount of
  #  data, choose a file system separated from the system to prevent
  #  saturation.
  download { "test suma-download":
    provider   => suma,
    ensure     => present,
    name       => "test suma-download",
    type       => "SP",
    root       => "/export/extra/puppet/suma",
    from       => "7100-03",
    to         => "7100-03-07-1614",
    lpp_source => "PAA_SP_7100-03_7100-03-07-1614",
  }
  # This declaration allows to perform suma-download through suma provider
  #  to get update of 7100-04 TL into /export/extra/puppet/suma
  #  for a system which is currently in 7100-03.
  # lpp_source created is named : PAA_TM_7100-03_7100-04
  #  (PAA prefix stands for Puppet AixAutomation)
  #  and this same name needs to be used to perform update, by using
  #  'patchmngt' declaration.
  # "/export/extra/puppet/suma" is the root directory of download.
  #  It should be an ad-hoc file system dedicated to download amount of
  #   data, choose a file system separated from the system to prevent
  #   saturation.
  download { "test suma-download2":
    provider   => suma,
    ensure     => present,
    name       => "test suma-download2",
    type       => "TL",
    root       => "/export/extra/puppet/suma",
    from       => "7100-03",
    to         => "7100-04",
  }
  # This declaration allows to perform suma-download through suma provider
  #  to get update of 7100-05 TL into /export/extra/puppet/suma
  #  for a system which is currently in 7100-03.
  # lpp_source created is named : PAA_TM_7100-03_7100-05
  #  (PAA prefix stands for Puppet AixAutomation)
  #  and this same name needs to be used to perform update, by using
  #  'patchmngt' declaration.
  # "/export/extra/puppet/suma" is the root directory of download.
  #  It should be an ad-hoc file system dedicated to download amount of
  #   data, choose a file system separated from the system to prevent
  #   saturation.
  download { "test suma-download3":
    provider   => suma,
    ensure     => present,
    name       => "test suma-download3",
    type       => "TL",
    root       => "/export/extra/puppet/suma",
    from       => "7100-03",
    to         => "7100-05",
  }
  # This declaration allows to perform cleaning of suma-download directory
  #  "/export/extra/puppet/suma/lpp_dource/SP/7100-037100-03-07-1614".
  #  Moreover the NIM resource "PAA_SP_7100-03_7100-03-07-1614" is removed.
  download { "test suma-download clean":
    provider   => suma,
    ensure     => absent,
    name       => "test suma-download clean",
    root       => "/export/extra/puppet/suma",
    lpp_source => "PAA_SP_7100-03_7100-03-07-1614",
  }
}
*/

/*
 I.2. Samples of NIM push update
   Declaration used here is 'patchmngt'.
*/
/*
class aixautomation {
  # This declaration allows to perform preview update only through nimpush provider:
  #  clio3 system update to the 7100-03-07-1614 SP is previewed.
  # The lpp_source is one NIM resource built by a 'download' declaration
  #  PAA_SP_7100-03_7100-03-07-1614
  patchmngt { "update clio3 to PAA_SP_7100-03_7100-03-07-1614":
    provider   => nimpush,
    ensure     => present,
    name       => "update clio3 to PAA_SP_7100-03_7100-03-07-1614",
    action     => "update",
    targets    => "clio3",
    sync       => "yes",
    lpp_source => "PAA_SP_7100-03_7100-03-07-1614",
    preview    => "yes",
  }
*/
/*
class aixautomation {
  # This declaration allows to perform update in apply mode through nimpush provider:
  #  clio3 system is updated to the 7100-03-07-1614 SP.
  # The lpp_source is one NIM resource built by a 'download' declaration
  #  PAA_SP_7100-03_7100-03-07-1614
  patchmngt { "update clio3 to PAA_SP_7100-03_7100-03-07-1614":
    provider   => nimpush,
    ensure     => present,
    name       => "update clio3 to PAA_SP_7100-03_7100-03-07-1614",
    action     => "update",
    targets    => "clio3",
    sync       => "yes",
    lpp_source => "PAA_SP_7100-03_7100-03-07-1614",
    preview    => "no",
  }
  # This declaration allows to perform reject of all updates (which were applied only)
  #  through nimpush provider: clio3 system comes back to its
  #  previous level 7100-03-05-1524 SP.
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
  # This declaration allows to perform update through nimpush provider:
  #  quimby07 system is updated to the 7100-03-07-1614 SP.
  # The lpp_source is the one built by download declaration
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
  # This declaration allows to perform update in apply mode through nimpush provider:
  #  clio4 system is updated to the 7100-03-08-1642 SP.
  # The lpp_source is one NIM resource built by a 'download' declaration
  #  PAA_SP_7100-03_7100-03-08-1642
  patchmngt { "update clio4 to PAA_SP_7100-03_7100-03-08-1642":
    provider   => nimpush,
    ensure     => present,
    name       => "update clio4 to PAA_SP_7100-03_7100-03-08-1642",
    action     => "update",
    targets    => "clio4",
    sync       => "yes",
    lpp_source => "PAA_SP_7100-03_7100-03-08-1642",
  }
  # This declaration allows to perform commit of all updates (which were applied only)
  #  through nimpush provider: clio4 system keeps its previous level
  #  7100-03-05-1524 SP.
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
 I.3. Samples of efix installation
   Declaration used here is 'fix'.
*/
/*
class aixautomation {
  # This declaration allows to install iFix through flrtvc provider:
  #  quimby01 and quimby02 systems are fixed (their necessary eFix are
  #  installed) as best as possible.
  # Setting ensure to 'present'
  # List of appropriate eFix is computed for each system, and then applied.
  # Possible steps are : runFlrtvc, parseFlrtvc, downloadFixes, checkFixes,
  #  buildResource, installResource.
  # "force" is by default set to 'yes', but if you want to spare time and
  #  reuse previous results of computation for each step, you can set "force"
  #  to 'no', as in example below.
  # "/export/extra/puppet/flrtvc" is suggested as root directory of download
  #  It should be an ad-hoc file system dedicated to download amount of
  #   data, choose a file system separated from the system to prevent
  #   saturation.
  fix { "example of eFix installation":
    provider => flrtvc,
    name     => "example of eFix installation",
    ensure   => present,
    to_step  => "installResource",
    targets  => "quimby01 quimby02",
    force    => "no",
    root     => "/export/extra/puppet/flrtvc",
  }
*/
/*
class aixautomation {
  # This declaration allows to remove iFix through flrtvc provider:
  #  quimby03 and quimby04 systems are cleaned from their eFix.
  # Setting ensure to 'absent'
  # All eFix are removed.
  fix { "example of eFix removal":
    provider => flrtvc,
    name     => "example of eFix removal",
    ensure   => absent,
    targets  => "quimby03 quimby04",
  }
}
*/


/*
 I.4. Samples of install and remove
   Declaration used here is 'patchmngt'.
*/
/*
class aixautomation {
  # This declaration allows to install lpp_source through nimpush provider:
  #  quimby01 and quimby02 systems are installed with a new NIM lpp_source.
  # Setting ensure to 'present'.
  # Action to be done is 'install'.
  # lpp_source to be installed : dos2unix, a very simple lpp_source containing
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
  # This declaration allows to remove lpp_source through nimpush provider,
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
I.5. Samples with all steps together:
   Declarations used here are 'download', 'patchmngt', and 'fix'.
 This sample shows how to update one LPAR 'castor8' to the last 721 SP, and
  install all efixes.
*/
/*
class aixautomation {
  download { "test PAA_SP_7200-01_7200-01-03-1720":
    provider => suma,
    ensure => present,
    name => "test PAA_SP_7200-01_7200-01-03-1720",
    type => "SP",
    root => "/exports/extra/test-puppet/suma",
    from => "7200-01",
    to => "7200-01-03-1720",
    to_step => "download",
    lpp_source => "PAA_SP_7200-01_7200-01-03-1720",
  }
  patchmngt { "update castor8 to 7200-01-03-1720":
    provider   => nimpush,
    ensure     => present,
    name       => "update castor8 to 7200-01-03-1720",
    action     => "update",
    targets    => "castor8",
    sync       => "yes",
    lpp_source => "PAA_SP_7200-01_7200-01-03-1720",
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
/*
 II. Samples of VIOS update
   Using 'vios' custom type.
  */
/*
 II.1 To perform health check (and only health check) on a single VIOS
  */
/*
class aixautomation {
    vios { 'vios_health_check_only_1':
      actions    => 'health',
      vios_pairs => '(p7jufv1)',
    }
}
*/
/*
 II.2 To perform health check (and only health check) on a VIOS pair
  */
/*
class aixautomation {
    vios { 'vios_health_check_only_2':
      actions    => 'health',
      vios_pairs => '(p7jufv1,p7jufv2)',
    }
}
*/

/*
 II.3 To perform check and save on a VIOS pair
  */
/*
class aixautomation {
    vios { 'vios_check_save_3':
      ensure     => present,
      actions    => 'check, save',
      vios_pairs => '(p7jufv1,p7jufv2)',
      altinst_rootvg_force => 'yes',
    }
}
*/
/*
 II.4 To perform check and save on a VIOS pair
 */
/*
class aixautomation {
    vios { 'vios_check_save_4':
      actions              => 'check, save',
      vios_pairs           => '(p7jufv1,p7jufv2)',
      altinst_rootvg_force => 'yes',
    }
}
/*
 II.5 To perform update in preview mode on a VIOS pair
  */
/*
class aixautomation {
    vios { 'vios_update_5':
      actions              => 'check, save, unmirror, autocommit, update',
      vios_pairs           => '(p7jufv1,p7jufv2)',
      options              => 'accept_licenses, preview',
      altinst_rootvg_force => 'yes',
      vios_lpp_sources     => 'p7jufv1=vios_update_22623_22631,p7jufv2=vios_update_22623_22631',
    }
}
*/
/*
 II.6 To perform update on two VIOS pairs
  */
/*
class aixautomation {
  vios { 'vios_update_6':
    actions              => 'check, save, unmirror, autocommit, update',
    vios_pairs           => '(p7juav1,p7juav2),(p7jufv1,p7jufv2)',
    options              => 'accept_licenses',
    altinst_rootvg_force => 'yes',
    vios_lpp_sources     => 'p7juav1=vios_update_22621_22631,p7juav2=vios_update_22621_22631,p7jufv1=vios_update_22623_22631,p7jufv2=vios_update_22623_22631',
  }
}
*/
