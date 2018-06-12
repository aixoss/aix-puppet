# TODO
* General
** Propose regex in targets parameter so that we can operations on a list of target generated from a
 regex.
** Propose 'master' as target so that all operations can be done on NIM master itself.
** Propose to exploit 'Reboot' needed to inform user when a reboot is needed after an install/update 
 eFix.
** Propose to work with an offline 'apar.csv'. Currently the last 'apar.csv' is downloaded each 
 time. 
** Propose automatic installation of a list of eFix by providing them by their names.
** Have a timeout on ftp download, and a retry mechanism.
** Restrict the standalones list analysed by facter 'standalones' to the list of targets provided in 
 manifests/init.pp but how to do that, as facter runs at the beginning, at a time manifests/init.pp 
 is not yet read
** Automatically compute Suma downloads scope taken into account "oslevel -s" of a list of 
 targets, currently this needs to be manually set by user, by using the 'from' and the 'to' 
 parameters of 'download' custom type

         
