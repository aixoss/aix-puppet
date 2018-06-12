# #
# # TODO : This file needs to be cleaned
# #
# class aixautomation {
#   fix { "ifix_remove":
#     provider => flrtvc,
#     name     => "ifix_remove",
#     ensure   => absent,
#     targets  => "quimby01 quimby02 quimby03 quimby04 quimby05 quimby06 quimby07 quimby08 quimby09 quimby10 quimby11 quimby12",
#   }
# }
# class aixautomation {
#   fix { "ifix_install":
#     provider => flrtvc,
#     name     => "ifix_install",
#     ensure   => present,
#     to_step  => "installResource",
#     targets  => "quimby01",
#     clean    => "yes",
#     root     => "/export/extra/puppet/flrtvc",
#   }
# }
# class aixautomation {
#   fix { "ifix_install":
#     provider => flrtvc,
#     name     => "ifix_install",
#     ensure   => absent,
#     to_step  => "installResource",
#     #level => "sec",
#     clean    => "no",
#     targets  => "quimby03",
#     root     => "/export/extra/puppet/flrtvc",
#   }
# }
class aixautomation {
  # This rule allows to perform download thru suma provider
  #  to get update of 7100-03-07-1614 SP into /export/extra/puppet/suma
  #  for a system which is currently in 7100-03
  # lpp_source created is named : PAA_SP_7100-03_7100-03-07-1614
  #  and this same name needs to be used to perform update
  # "/export/extra/puppet/suma" is the root directory of download
  #  It should be an ad hoc file system dedicated to download
  #   data, keep this file system separated from the system to prevent
  #   saturation.
  download { "my_download_714":
    provider   => suma,
    ensure     => present,
    name       => "my_download_714",
    type       => "SP",
    root       => "/export/extra/puppet/suma",
    from       => "7100-04",
    to         => "7100-04-01-1543",
    to_step    => "download",
    lpp_source => "PAA_SP_7100-04_7100-04-01-1543",
  }
  patchmngt { "update quimby09 to 7100-04-01-1543":
    provider   => nimpush,
    ensure     => present,
    name       => "update quimby09 to 7100-04-01-1543",
    action     => "update",
    targets    => "quimby10",
    sync       => "yes",
    lpp_source => "PAA_SP_7100-04_7100-04-01-1543",
  }
}
#   # This rule allows to perform download thru suma provider
#   #  to get update of 7100-04 TL into /export/extra/puppet/suma
#   #  for a system which is currently in 7100-03
#   # lpp_source created is named : PAA_TM_7100-03_7100-04
#   #  and this same name needs to be used to perform update
#   # "/export/extra/puppet/suma" is the root directory of download
#   #  It should be an ad hoc file system dedicated to download
#   #   data, keep this file system separated from the system to prevent
#   #   saturation.
#   download { "my_download_4":
#     provider => suma,
#     ensure   => present,
#     name     => "my_download_4",
#     type     => "TL",
#     root     => "/export/extra/puppet/suma",
#     from     => "7100-03",
#     to       => "7100-04",
#   }
#   # This rule allows to perform download thru suma provider
#   #  to get update of 7100-05 TL into /export/extra/puppet/suma
#   #  for a system which is currently in 7100-03
#   # lpp_source created is named : PAA_TM_7100-03_7100-05
#   #  and this same name needs to be used to perform update
#   # "/export/extra/puppet/suma" is the root directory of download
#   #  It should be an ad hoc file system dedicated to download
#   #   data, keep this file system separated from the system to prevent
#   #   saturation.
#   download { "my_download_5":
#     provider => suma,
#     ensure   => present,
#     name     => "my_download_5",
#     type     => "TL",
#     root     => "/export/extra/puppet/suma",
#     from     => "7100-03",
#     to       => "7100-05",
#   }
#   # This rule allows to perform cleaning of download directory
#   #  "/export/extra/puppet/suma/lpp_dource/SP/7100-037100-03-07-1614""
#   #  Moreover the NIM resource "PAA_SP_7100-03_7100-03-07-1614" is removed.
#   download { "my_clean_3":
#     provider   => suma,
#     ensure     => absent,
#     name       => "my_clean_3",
#     type       => "SP",
#     root       => "/export/extra/puppet/suma",
#     from       => "7100-03",
#     to         => "7100-03-07-1614",
#     lpp_source => "PAA_SP_7100-03_7100-03-07-1614",
#   }
# }
# class aixautomation {
#   patchmngt { "dos2unix_mngt2":
#     provider   => nimpush,
#     ensure     => absent,
#     name       => "dos2unix_mngt2",
#     action     => "install",
#     lpp_source => "dos2unix",
#     targets    => "quimby01, quimby02",
#     sync       => "yes",
#   }
# }
# patchmngt { "dos2unix_mngt4":
#   provider  => nimpush,
#   ensure    => absent,
#   name      => "dos2unix_mngt4",
#   action    => "install",
#   lpp_source => "dos2unix",
#   targets   => "quimby04",
#   sync      => "yes",
# }
# tested ok
### OK 30 mars apply reject
# patchmngt { "dos2unix_mngt":
#   provider => nimpush ,
#   ensure => absent,
#   name => "dos2unix_mngt",
#   action => "install",
#   lpp_source => "dos2unix",
#   targets => "quimby03, quimby04",
#   sync => "yes",
#   #targets => aixautomation::getstandalones(),
# }
### OK 30 mars apply reject
#
# download { "my_download":
#   provider => suma,
#   ensure => present,
#   name => "my_download",
#   type => "SP",
#   root => "/export/extra/puppet/suma",
#   from => "7100-03",
#   to => "7100-03-01-1341",
# }
# OK, and normal to be OK
# download { "my_download":
#   provider => suma,
#   ensure => present,
#   name => "my_download",
#   type => "Latest",
#   root => "/export/extra/puppet/suma",
#   from => "7100-02",
# }
# KO, and normal to be KO
# download { "my_download":
#   provider => suma,
#   ensure => present,
#   name => "my_download",
#   type => "Latest",
#   root => "/export/extra/puppet/suma",
#   from => "7100-02-02-1316",
# }
# OK, and normal to be OK
# download { "my_download":
#   provider => suma,
#   ensure => present,
#   name => "my_download",
#   type => "TL",
#   root => "/export/extra/puppet/suma",
#   from => "7100-04",
#   to => "7100-05",
# }
# OK, and normal to be OK
############## OK March 28
# download { "my_download1":
#   provider => suma,
#   ensure => present,
#   name => "my_download1",
#   type => "Latest",
#   root => "/export/extra/puppet/suma",
#   from => "7100-01",
# }
# patchmngt { "update quimby9 to Latest 7100-01":
#   provider  => nimpush ,
#   ensure    => present,
#   name      => "update quimby9 to Latest 7100-01",
#   action    => "update",
#   targets   => "quimby09",
#   sync      => "yes",
#   lpp_source => "PAA_Latest_7100-01",
# }
############## OK March 28
##### NOT OK, SUMA DOES NOT BUILD CONSISTENT DOWNLOAD, UPDAT IMPOSSIBLE 29 march
# download { "my_download2":
#   provider => suma,
#   ensure => present,
#   name => "my_download2",
#   type => "Latest",
#   root => "/export/extra/puppet/suma",
#   from => "7100-02",
# }
# patchmngt { "update quimby10 to Latest 7100-02":
#   provider  => nimpush ,
#   ensure    => present,
#   name      => "update quimby10 to Latest 7100-02",
#   action    => "update",
#   targets   => "quimby10",
#   sync      => "yes",
#   lpp_source => "PAA_Latest_7100-02",
# }
##### NOT OK, SUMA DOES NOT BUILD CONSISTENT DOWNLOAD, UPDAT IMPOSSIBLE 29 march

#############OK April 4th
# download { "my_download3":
#   provider => suma,
#   ensure => present,
#   name => "my_download3",
#   type => "Latest",
#   root => "/export/extra/puppet/suma",
#   from => "7100-00",
# }
# patchmngt { "update quimby11 quimby12 to Latest 7100-00":
#   provider  => nimpush ,
#   ensure    => present,
#   name      => "update quimby11 quimby12 to Latest 7100-00",
#   action    => "update",
#   targets   => "quimby11 quimby12",
#   sync      => "yes",
#   lpp_source => "PAA_Latest_7100-00",
# }
#############OK April 4th

#############NOT OK April 4th
# download { "my_download3":
#   provider => suma,
#   ensure => present,
#   name => "my_download3",
#   type => "SP",
#   root => "/export/extra/puppet/suma",
#   from => "7100-00",
#   to => "7100-01-10-1415",
# }
# patchmngt { "update quimby11 quimby12 to 7100-01-10-1415":
#   provider  => nimpush ,
#   ensure    => present,
#   name      => "update quimby11 quimby12 to 7100-01-10-1415",
#   action    => "update",
#   targets   => "quimby11 quimby12",
#   sync      => "yes",
#   lpp_source => "PAA_SP_7100-00_7100-01-10-1415",
# }
############# quimby11 and 12 remain in 7100-00-10-1334
############# and ssh quimby11 /bin/lslpp -lcq | /bin/grep APPLIED | wc -l returns 305
#############NOT OK April 4th

############# OK April 4th
# download { "download Latest TL3":
#   provider => suma,
#   ensure => present,
#   name => "download Latest TL3",
#   type => "Latest",
#   root => "/export/extra/puppet/suma",
#   from => "7100-03",
# }
# patchmngt { "quimby04 to Latest 7100-03":
#   provider  => nimpush ,
#   ensure    => present,
#   name      => "quimby04 to Latest 7100-03",
#   action    => "update",
#   targets   => "quimby04",
#   sync      => "yes",
#   lpp_source => "PAA_Latest_7100-03",
# }
############# It takes more than 2 hours to update 7130 to 713 latest
############# OK April 4th



##### NOT OK, EVEN SECOND TIME IT DOES NOT WORK MEANING SUMAPACKAGE IS INCOMPLET OR INCONSISTENT 29 march
# download { "my_download3":
#   provider => suma,
#   ensure => present,
#   name => "my_download3",
#   type => "Latest",
#   root => "/export/extra/puppet/suma",
#   from => "7100-01",
# }
# patchmngt { "update quimby12 to Latest 7100-01":
#   provider  => nimpush ,
#   ensure    => present,
#   name      => "update quimby12 to Latest 7100-01",
#   action    => "update",
#   targets   => "quimby12",
#   sync      => "yes",
#   lpp_source => "PAA_Latest_7100-01",
# }
##### NOT OK, EVEN SECOND TIME IT DOES NOT WORK, MEANING SUMAPACKAGE IS INCOMPLET OR INCONSISTENT 29 march


##### NOT OK, TL 7111 is OLDER THAN 710-10, UPDAT IMPOSSIBLE 29 march
# download { "my_download1":
#    provider => suma,
#    ensure => present,
#    name => "my_download1",
#    type => "TL",
#    root => "/export/extra/puppet/suma",
#    from => "7100-00",
#    to => "7100-01",
#  }
# BUILDDATE 1036
# BUILDDATE 1115
# BUILDDATE 1140
# BUILDDATE 1141

#  patchmngt { "update quimby1 to TL 7100-01":
#    provider  => nimpush ,
#    ensure    => present,
#    name      => "update quimby1 TL 7100-01",
#    action    => "update",
#    targets   => "quimby01",
#    sync      => "yes",
#    lpp_source => "PAA_TL_7100-00_7100-01",
#  }
##### NOT OK, TL 7111 is OLDER THAN 710-10, UPDAT IMPOSSIBLE 29 march


##### NOT OK, 29 march
# download { "my_download4":
#   provider => suma,
#   ensure => present,
#   name => "my_download4",
#   type => "SP",
#   root => "/export/extra/puppet/suma",
#   from => "7100-00",
#   to => "7100-01-10-1415",
# }
# patchmngt { "update quimby4 to SP 7100-01-10-1415":
#   provider  => nimpush ,
#   ensure    => present,
#   name      => "update quimby4 SP 7100-01-10-1415",
#   action    => "update",
#   targets   => "quimby04",
#   sync      => "no",
#   lpp_source => "PAA_SP_7100-00_7100-01-10-1415",
# }
##### NOT OK, 29 march

##### WAIT FOR  RESULT
##### OK it remains only 9 APPLIED instead of 317
# patchmngt { "reject on quimby04":
#   provider  => nimpush ,
#   ensure    => absent,
#   name      => "reject on quimby04",
#   action    => "update",
#   targets   => "quimby04",
#   mode      => "reject",
#   sync      => "yes",
# }
##### OK it remains only 9 APPLIED instead of 317

##### OK it remains only 9 APPLIED instead of 317
##### KO if run a second time still 9 APPLIED
# patchmngt { "reject on quimby11 12":
#   provider  => nimpush ,
#   ensure    => absent,
#   name      => "reject on quimby11 12",
#   action    => "update",
#   targets   => "quimby11, quimby12",
#   mode      => "reject",
#   sync      => "yes",
# }
##### OK it remains only 9 APPLIED instead of 317
##### KO if run a second time still 9 APPLIED

# download { "my_download3":
#   provider => suma,
#   ensure => present,
#   name => "my_download3",
#   type => "SP",
#   root => "/export/extra/puppet/suma",
#   from => "7100-00",
#   to => "7100-01-10-1415",
# }
# patchmngt { "update quimby01 to last SP of 7100-01":
#   provider  => nimpush,
#   ensure    => present,
#   name      => "update quimby01 to last SP of 7100-01",
#   action    => "update",
#   targets   => "quimby01",
#   sync      => "yes",
#   lpp_source => "PAA_SP_7100-00_7100-01-10-1415",
# }
# download { "my_download4":
#   provider => suma,
#   ensure => present,
#   name => "my_download4",
#   type => "SP",
#   root => "/export/extra/puppet/suma",
#   from => "7100-00",
#   to => "7100-02-07-1524",
# }
# patchmngt { "update quimby02 to 7100-02-07-1524":
#   provider  => nimpush,
#   ensure    => present,
#   name      => "update quimby02 to 7100-02-07-1524",
#   action    => "update",
#   targets   => "quimby02",
#   sync      => "yes",
#   lpp_source => "PAA_SP_7100-00_7100-02-07-1524",
# }
# download { "my_download5":
#   provider => suma,
#   ensure => present,
#   name => "my_download5",
#   type => "SP",
#   root => "/export/extra/puppet/suma",
#   from => "7100-00",
#   to => "7100-03-09-1717",
# }
# patchmngt { "update quimby03 to 7100-03-09-1717":
#   provider  => nimpush,
#   ensure    => present,
#   name      => "update quimby03 to 7100-03-09-1717",
#   action    => "update",
#   targets   => "quimby03",
#   sync      => "yes",
#   lpp_source => "PAA_SP_7100-00_7100-03-09-1717",
# }
#
# download { "my_download6":
#   provider => suma,
#   ensure => present,
#   name => "my_download6",
#   type => "TL",
#   root => "/export/extra/puppet/suma",
#   from => "7100-00",
#   to => "7100-03",
# }
# patchmngt { "update quimby04 to 7100-03":
#   provider  => nimpush,
#   ensure    => present,
#   name      => "update quimby04 to 7100-03",
#   action    => "update",
#   targets   => "quimby04",
#   sync      => "yes",
#   lpp_source => "PAA_TL_7100-00_7100-03",
#}
# download { "my_download7":
#   provider => suma,
#   ensure => present,
#   name => "my_download7",
#   type => "TL",
#   root => "/export/extra/puppet/suma",
#   from => "7100-00",
#   to => "7100-04",
# }
# patchmngt { "update quimby05 to 7100-04":
#   provider  => nimpush,
#   ensure    => present,
#   name      => "update quimby05 to 7100-04",
#   action    => "update",
#   targets   => "quimby05",
#   sync      => "yes",
#   lpp_source => "PAA_TL_7100-00_7100-04",
# }
#
# download { "my_download4":
#   provider => suma,
#   ensure => present,
#   name => "my_download4",
#   type => "SP",
#   root => "/export/extra/puppet/suma",
#   from => "7100-00",
#   to => "7100-01-10-1415",
# }
# patchmngt { "update quimby12 to last SP of 7100-01":
#   provider  => nimpush ,
#   ensure    => present,
#   name      => "update quimby12 to last SP of 7100-01",
#   action    => "update",
#   targets   => "quimby12",
#   sync      => "yes",
#   lpp_source => "PAA_SP_7100-00_7100-01-10-1415",
# }

# download { "my_download2":
#   provider => suma,
#   ensure => present,
#   name => "my_download2",
#   type => "SP",
#   root => "/export/extra/puppet/suma",
#   from => "7100-00-10-1334",
#   to => "7100-01-02-1150",
# }
# download { "my_download31":
#   provider => suma,
#   ensure => present,
#   name => "my_download31",
#   type => "TL",
#   root => "/export/extra/puppet/suma",
#   from => "7100-00",
#   to => "7100-01-03-1207",
# }
# download { "my_download32":
#   provider => suma,
#   ensure => present,
#   name => "my_download32",
#   type => "SP",
#   root => "/export/extra/puppet/suma",
#   from => "7100-00",
#   to => "7100-01-03-1207",
# }
# download { "my_download33":
#   provider => suma,
#   ensure => present,
#   name => "my_download33",
#   type => "TL",
#   root => "/export/extra/puppet/suma",
#   from => "7100-00",
#   to => "7100-01-10-1415",
# }

# status before={
#   "quimby01"=>{"oslevel -s"=>"7100-03-01-1341", "lslpp -e"=>""},
#   "quimby02"=>{"oslevel -s"=>"7100-03-02-1412", "lslpp -e"=>""},
#   "quimby03"=>{"oslevel -s"=>"7100-03-01-1341", "lslpp -e"=>""},
#   "quimby04"=>{"oslevel -s"=>"7100-03-09-1717", "lslpp -e"=>""},
#   "quimby05"=>{"oslevel -s"=>"7100-03-00-0000", "lslpp -e"=>""},7100-03-07-1614
#   "quimby07"=>{"oslevel -s"=>"7100-01-00-0000", "lslpp -e"=>""},
#   "quimby08"=>{"oslevel -s"=>"7100-01-10-1415", "lslpp -e"=>""},
#   "quimby09"=>{"oslevel -s"=>"7100-01-10-1415", "lslpp -e"=>""},
#   "quimby11"=>{"oslevel -s"=>"7100-00-10-1334", "lslpp -e"=>""},
#   "quimby12"=>{"oslevel -s"=>"7100-00-10-1334", "lslpp -e"=>""}}
# class aixautomation {
#   # download { "my_download_2_1":
#   #   provider   => suma,
#   #   ensure     => present,
#   #   name       => "my_download_2_1",
#   #   type       => "TL",
#   #   root       => "/export/extra/puppet/suma",
#   #   from       => "7100-01",
#   #   to         => "7100-03",
#   #   lpp_source => "PAA_TL_7100-01_7100-03",
#   # }
#
#   download { "my_download_2_2":
#     provider   => suma,
#     ensure     => present,
#     name       => "my_download_2_2",
#     type       => "SP",
#     root       => "/export/extra/puppet/suma",
#     from       => "7100-03",
#     to         => "7100-03-07-1614",
#     lpp_source => "PAA_SP_7100-03_7100-03-07-1614",
#   }
#
#   # patchmngt { "update quimby07 to 7100-03":
#   #   provider   => nimpush,
#   #   ensure     => present,
#   #   name       => "update quimby07 to 7100-03",
#   #   action     => "update",
#   #   targets    => "quimby07",
#   #   sync       => "yes",
#   #   lpp_source => "PAA_TL_7100-01_7100-03",
#   # }
#
#   patchmngt { "update quimby07 to 7100-03-07-1614":
#     provider   => nimpush,
#     ensure     => present,
#     name       => "update quimby07 to 7100-03-07-1614",
#     action     => "update",
#     targets    => "quimby07",
#     sync       => "yes",
#     lpp_source => "PAA_SP_7100-03_7100-03-07-1614",
#   }
#
# }
# # patchmngt { "reboot quimby05":
#   provider  => nimpush,
#   ensure    => present,
#   name      => "reboot quimby05",
#   action    => "reboot",
#   targets   => "quimby05",
#   sync      => "yes",
# }
# download { "my_download_2_2":
#   provider => suma,
#   ensure => present,
#   name => "my_download_2_2",
#   type => "SP",
#   root => "/export/extra/puppet/suma",
#   from => "7100-03",
#   to => "7100-03-08-1642",
# }
# download { "my_download_2_3":
#   provider => suma,
#   ensure => present,
#   name => "my_download_2_3",
#   type => "SP",
#   root => "/export/extra/puppet/suma",
#   from => "7100-03",
#   to => "7100-03-09-1717",
# }
# patchmngt { "update quimby02 to 7100-03-08-1642":
#   provider  => nimpush ,
#   ensure    => present,
#   name      => "update quimby02 to 7100-03-08-1642",
#   action    => "update",
#   targets   => "quimby02",
#   sync      => "yes",
#   lpp_source => "PAA_SP_7100-03_7100-03-08-1642",
# }
# patchmngt { "update quimby03 to 7100-03-09-1717":
#   provider  => nimpush ,
#   ensure    => present,
#   name      => "update quimby03 to 7100-03-09-1717",
#   action    => "update",
#   targets   => "quimby03",
#   sync      => "yes",
#   lpp_source => "PAA_SP_7100-03_7100-03-09-1717",
# }

#  tout ceci a échoué lamentablement et il faudrait regarder
#   comment ça se comporte avec Chef
#
# "quimby01"=>{"oslevel -s"=>"7100-03-01-1341", "lslpp -e"=>""},
# "quimby02"=>{"oslevel -s"=>"7100-03-09-1717", "lslpp -e"=>""},
# "quimby03"=>{"oslevel -s"=>"7100-03-05-1524", "lslpp -e"=>""},
# "quimby04"=>{"oslevel -s"=>"7100-03-09-1717", "lslpp -e"=>""},
# "quimby05"=>{"oslevel -s"=>"7100-03-07-1614", "lslpp -e"=>""},
# "quimby07"=>{"oslevel -s"=>"7100-01-10-1415", "lslpp -e"=>""},
# "quimby08"=>{"oslevel -s"=>"7100-01-10-1415", "lslpp -e"=>""},
# "quimby09"=>{"oslevel -s"=>"7100-01-10-1415", "lslpp -e"=>""},
# "quimby11"=>{"oslevel -s"=>"7100-00-10-1334", "lslpp -e"=>""},
# "quimby12"=>{"oslevel -s"=>"7100-00-10-1334", "lslpp -e"=>""}
#
# download { "my_download_2_4":
#   provider => suma,
#   ensure   => present,
#   name     => "my_download_2_4",
#   type     => "Latest",
#   root     => "/export/extra/puppet/suma",
#   from     => "7100-04",
# }
# patchmngt { "update quimby07 to 7100-07":
#   provider  => nimpush,
#   ensure    => present,
#   name      => "update quimby07 to 7100-07",
#   action    => "update",
#   targets   => "quimby07",
#   sync      => "yes",
#   lpp_source => "PAA_Latest_7100-04",
# }
# download { "my_download_2_5":
#   provider => suma,
#   ensure   => present,
#   name     => "my_download_2_5",
#   type     => "Latest",
#   root     => "/export/extra/puppet/suma",
#   from     => "7100-05",
# }
# patchmngt { "update quimby08 to 7100-08":
#   provider  => nimpush,
#   ensure    => present,
#   name      => "update quimby08 to 7100-08",
#   action    => "update",
#   targets   => "quimby08",
#   sync      => "yes",
#   lpp_source => "PAA_Latest_7100-05",
# }
/*
"quimby01"=>{"oslevel -s"=>"7100-03-01-1341", "lslpp -e"=>""},
"quimby02"=>{"oslevel -s"=>"7100-03-09-1717", "lslpp -e"=>""},
"quimby03"=>{"oslevel -s"=>"7100-03-05-1524", "lslpp -e"=>""},
"quimby04"=>{"oslevel -s"=>"7100-03-09-1717", "lslpp -e"=>""},
"quimby05"=>{"oslevel -s"=>"7100-03-07-1614", "lslpp -e"=>""},
"quimby07"=>{"oslevel -s"=>"7100-01-00-0000", "lslpp -e"=>""},
"quimby08"=>{"oslevel -s"=>"7100-01-10-1415", "lslpp -e"=>""},
"quimby09"=>{"oslevel -s"=>"7100-01-10-1415", "lslpp -e"=>""},
"quimby11"=>{"oslevel -s"=>"7100-00-10-1334", "lslpp -e"=>""},
"quimby12"=>{"oslevel -s"=>"7100-00-10-1334", "lslpp -e"=>""}
*/
/*
"quimby01"=>{"oslevel -s"=>"7100-03-01-1341", "lslpp -e"=>""},
"quimby02"=>{"oslevel -s"=>"7100-03-09-1717", "lslpp -e"=>""},
"quimby03"=>{"oslevel -s"=>"7100-03-05-1524", "lslpp -e"=>""},
"quimby04"=>{"oslevel -s"=>"7100-03-09-1717", "lslpp -e"=>""},
"quimby05"=>{"oslevel -s"=>"7100-03-07-1614", "lslpp -e"=>""},
"quimby07"=>{"oslevel -s"=>"7100-01-10-1415", "lslpp -e"=>""},
"quimby08"=>{"oslevel -s"=>"7100-01-10-1415", "lslpp -e"=>""},
"quimby09"=>{"oslevel -s"=>"7100-01-10-1415", "lslpp -e"=>""},
"quimby11"=>{"oslevel -s"=>"7100-00-10-1334", "lslpp -e"=>""},
"quimby12"=>{"oslevel -s"=>"7100-00-10-1334", "lslpp -e"=>""}
*/

# patchmngt { "reboot quimby07 08":
#   provider  => nimpush,
#   ensure    => present,
#   name      => "reboot quimby07 08",
#   action    => "reboot",
#   targets   => "quimby07 quimby08",
#   sync      => "yes",
# }
# update { "my_update":
#   ensure => present,
#   name => "my_update",
#   targets => "quimby08",
#   to => "7100-01-01-1141",
#   root => "/export/extra/puppet/suma",
#   sync => "yes",
# }
# patchmngt { "update quimby08 to 7100-01-10-1415":
#   provider  => nimpush ,
#   ensure    => present,
#   name      => "update quimby08 to 7100-01-10-1415",
#   action    => "update",
#   targets   => "quimby08",
#   sync      => "yes",
#   lpp_source => "PAA_SP_7100-00_7100-01-10-1415",
# }
# download { "my_download34":
#   provider => suma,
#   ensure => present,
#   name => "my_download34",
#   type => "SP",
#   root => "/export/extra/puppet/suma",
#   from => "7100-00",
#   to => "7100-01-10-1415",
# }
# patchmngt { "update quimby08 to 7100-01-10-1415":
#   provider  => nimpush ,
#   ensure    => present,
#   name      => "update quimby08 to 7100-01-10-1415",
#   action    => "update",
#   targets   => "quimby08",
#   sync      => "yes",
#   lpp_source => "PAA_SP_7100-00_7100-01-10-1415",
# }
# patchmngt { "update quimby09,quimby10 to 7100-01-10-1415":
#   provider  => nimpush ,
#   ensure    => present,
#   name      => "update quimby09,quimby10 to 7100-01-10-1415",
#   action    => "update",
#   targets   => "quimby09, quimby10",
#   sync      => "yes",
#   lpp_source => "PAA_SP_7100-00_7100-01-10-1415",
# }
#patchmngt { "update quimby09 to 7100-01-03-1207":
#   provider  => nimpush ,
#   ensure    => present,
#   name      => "update quimby09 to 7100-01-03-1207",
#   action    => "update",
#   targets   => "quimby09",
#   sync      => "yes",
#   lpp_source => "PAA_7100-00-10-1334_7100-01-03-1207",
# }
# download { "my_download4":
#   provider => suma,
#   ensure => present,
#   name => "my_download4",
#   type => "SP",
#   root => "/export/extra/puppet/suma",
#   from => "7100-00-10-1334",
#   to => "7100-01-04-1216",
# }
# patchmngt { "update quimby10 to 7100-01-04-1216":
#   provider  => nimpush ,
#   ensure    => present,
#   name      => "update quimby10 to 7100-01-04-1216",
#   action    => "update",
#   targets   => "quimby10",
#   sync      => "yes",
#   lpp_source => "PAA_7100-00-10-1334_7100-01-04-1216",
# }
# download { "my_download5":
#   provider => suma,
#   ensure => present,
#   name => "my_download5",
#   type => "SP",
#   root => "/export/extra/puppet/suma",
#   from => "7100-00-10-1334",
#   to => "7100-01-05-1228",
# }
# patchmngt { "update quimby11 to 7100-01-05-1228":
#   provider  => nimpush ,
#   ensure    => present,
#   name      => "update quimby10 to 7100-01-05-1228",
#   action    => "update",
#   targets   => "quimby11",
#   sync      => "yes",
#   lpp_source => "PAA_7100-00-10-1334_7100-01-05-1228",
# }
# download { "my_download6":
#   provider => suma,
#   ensure => present,
#   name => "my_download6",
#   type => "SP",
#   root => "/export/extra/puppet/suma",
#   from => "7100-00-10-1334",
#   to => "7100-01-06-1241",
# }
# patchmngt { "update quimby12 to 7100-01-06-1241":
#   provider  => nimpush ,
#   ensure    => present,
#   name      => "update quimby12 to 7100-01-06-1241",
#   action    => "update",
#   targets   => "quimby12",
#   sync      => "yes",
#   lpp_source => "PAA_7100-00-10-1334_7100-01-06-1241",
# }
#
# Info:  0500-035 No fixes match your query.
# download { "my_download":
#   provider => suma,
#   ensure => present,
#   name => "my_download",
#   type => "TL",
#   root => "/export/extra/puppet/suma",
#   from => "7100-04",
#   to => "7100-05-02-1810",
# }
# download { "my_download":
#   provider => suma,
#   ensure => present,
#   name => "my_download",
#   type => "TL",
#   root => "/export/extra/puppet/suma",
#   from => "7100-02",
#   to => "7100-03-01-1341",
# }
# download { "my_download":
#   provider => suma,
#   ensure => present,
#   name => "my_download",
#   type => "TL",
#   root => "/export/extra/puppet/suma",
#   from => "7100-02",
#   to => "7100-04",
# }
# patchmngt { "update XYZ":
#   provider  => nimpush ,
#   ensure    => present,
#   name      => "update XYZ",
#   action    => "update",
#   mode      => "apply",
#   targets   => "quimby04",
#   sync      => "yes",
#   lpp_source => "U8748_12_13",
# }
#
#tested ok
# patchmngt { "reboot_mngt":
#   provider => nimpush ,
#   ensure => present,
#   action => "reboot",
#   targets => aixautomation::getstandalones(),
# }
# patchmngt { "reboot_mngt":
#   provider => nimpush ,
#   ensure => present,
#   action => "reboot",
#   targets => "quimby12",
# }
#
# tested ok, in async mode
# patchmngt { "install_ssh_ssl":
#   provider => nimpush ,
#   ensure => present,
#   name => "ssh_ssl",
#   action => "install",
#   lpp_source => "ssh_ssl",
#   targets => "quimby06,quimbyKO,quimby07,quimby09,quimby10",
# }
#
# # tested ok
#
# lpar { "quimby02":
#   oslevel => "7100-03-03-1415",
# }
#
# # # tested ok
# patchmngt { "update XYZ":
#   provider  => nimpush ,
#   ensure    => present,
#   name      => "update XYZ",
#   action    => "update",
#   mode      => "apply",
#   targets   => "quimby01",
#   sync      => "yes",
#   lpp_source => "7100-05-01",
# }
# patchmngt { "update XYZ":
#   provider  => nimpush,
#   ensure    => present,
#   name      => "update XYZ",
#   action    => "update",
#   mode      => "apply",
#   targets   => "quimby04",
#   sync      => "yes",
#   lpp_source => "U8748_12_13",
# }
#
#   provider => nimpush ,
#   name => "7100-04-05-1720-lpp_source",
#   action => "update",
#   sync => "yes",
#   mode => "apply",
#   lpp_source => "7100-04-05-1720-lpp_source",
#   targets => "quimby05",
# }
#
# patchmngt { "7100-04-03-1642 => 7100-04-05-1720":
#   provider => nimpush ,
#   name => "7100-04-05-1720-lpp_source",
#   action => "update",
#   sync => "yes",
#   mode => "commit",
#   lpp_source => "7100-04-05-1720-lpp_source",
#   targets => "quimby05",
# }
#
# patchmngt { "7100-04-03-1642 => 7100-04-05-1720":
#   provider => nimpush ,
#   name => "7100-04-05-1720-lpp_source",
#   action => "update",
#   sync => "yes",
#   mode => "reject",
#   lpp_source => "7100-04-05-1720-lpp_source",
#   targets => "quimby05",
# }
#DOWNLOAD DIRECTORY : /etc/puppet/modules/data/lpp_sources/SP/7100-03/7100-03-01-1341/installp/ppc
#NIM LPPSOURCE : PAA_SP_7100-03_7100-03-01-1341
# download { "download_TL3_SP1":
#     provider => suma,
#     ensure => present,
#     name => "download_TL3_SP1",
#     type => "SP",
#     root => "/export/extra/puppet/suma",
#     from => "7100-03",
#     to => "7100-03-01-1341",
#   }
# patchmngt { "quimby03 to 7100-03-01-1341":
#   provider  => nimpush ,
#   ensure    => present,
#   name      => "quimby03 to 7100-03-01-1341",
#   action    => "update",
#   targets   => "quimby03",
#   sync      => "yes",
#   lpp_source => "PAA_SP_7100-03_7100-03-01-1341",
#}
# download { "download_TL3_SP2":
#   provider => suma,
#   ensure => present,
#   name => "download_TL3_SP2",
#   type => "SP",
#   root => "/export/extra/puppet/suma",
#   from => "7100-03",
#   to => "7100-03-02-1412",
# }
# patchmngt { "quimby02 to 7100-03-02-1412":
#   provider  => nimpush ,
#   ensure    => present,
#   name      => "quimby02 to 7100-03-02-1412",
#   action    => "update",
#   targets   => "quimby02",
#   sync      => "yes",
#   lpp_source => "PAA_SP_7100-03_7100-03-02-1412",
# }
# download { "download_TL3_SP3":
#   provider => suma,
#   ensure => present,
#   name => "download_TL3_SP3",
#   type => "SP",
#   root => "/export/extra/puppet/suma",
#   from => "7100-03",
#   to => "7100-03-03-1415",
# }
# download { "download_TL3_SP4":
#   provider => suma,
#   ensure => present,
#   name => "download_TL3_SP4",
#   type => "SP",
#   root => "/export/extra/puppet/suma",
#   from => "7100-03",
#   to => "7100-03-04-1441",
# }
# download { "download_TL3_SP5":
#   provider => suma,
#   ensure => present,
#   name => "download_TL3_SP5",
#   type => "SP",
#   root => "/export/extra/puppet/suma",
#   from => "7100-03",
#   to => "7100-03-05-1524",
# }
#}
