# TODO
* General
** Propose regex in targets parameter so that we can perform operations on a list of targets 
 generated from a regex.
** Check updates consistency before trying, by looking at the BUILDDATE from the "oslevel-s", and 
 by comparing with BUILDDATE of the update.  
** Propose 'master' as target so that all operations can be done on NIM master itself.
** Propose to exploit 'Reboot' needed to inform user when a reboot is needed after an install/update 
 eFix.
** Propose to work with an offline 'apar.csv'. Currently the last 'apar.csv' is downloaded each 
 time. 
** Propose automatic installation of a list of eFix by providing them by their names.
** Have a timeout on ftp download, and a retry mechanism.
** Restrict the standalones list analysed by facter 'standalones' to the list of targets provided in 
 manifests/init.pp but how to do that, as facter runs at the beginning, at a time manifests/init.pp 
 is not yet read.
** Automatically compute Suma downloads scope taken into account "oslevel -s" of a list of 
 targets, currently this needs to be manually set by user, by using the 'from' and the 'to' 
 parameters of 'download' custom type.
** Have a consistent color-code for displaying messages onto the console :
 red:error messages, yellow:warning, blue:info, green:debug. 
 Today this color-code is not enforced everywhere, even if there is a good start.
** Propose a nice interface to display SP per TL results to user
** Suma preview is likely to be unnecessary if 'to_step' is set to 'download'. Consider skipping 
 this preview step in this case.
** Verify Idempotence
** In case of updates of several LPARs, launch these updates in parallel, as each update is quite 
 long
** Update in preview mode only to see what would be done.
** Display manifests/init.pp at the beginning of the log, so that we can know what is being applied.  
  
  

         
