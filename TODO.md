# TODO AND DONE LISTS
## TODO
* General
** 1. Propose regex in targets parameter so that we can perform operations on a list of targets 
 generated from a regex.
** 2. Check updates consistency before trying, by looking at the BUILDDATE from the "oslevel -s", and 
 by comparing with BUILDDATE of the update.  
** 3. Propose 'master' as target so that all operations can be done on NIM master itself.
** 4. Propose to exploit 'Reboot needed' to inform user when a reboot is needed after an install/update 
 eFix.
** 5. Propose to work with an offline 'apar.csv'. Currently the last 'apar.csv' is downloaded each 
 time. 
** 6. Propose automatic installation of a list of eFix by providing them by their names.
** 7. Have a timeout on ftp download, and a retry mechanism.
** 8. Restrict the standalones list analysed by facter 'standalones' to the list of targets provided in 
 manifests/init.pp but how to do that, as facter runs at the beginning, at a time manifests/init.pp 
 is not yet read.
** 9. Automatically compute Suma downloads scope taken into account "oslevel -s" of a list of 
 targets, currently this needs to be manually set by user, by using the 'from' and the 'to' 
 parameters of 'download' custom type.
** 10. Have a consistent color-code for displaying messages onto the console :
 red:error messages, yellow:warning, blue:info, green:debug. 
 Today this color-code is not enforced everywhere, even if there is a good start.
** 11. Verify Idempotence
** 12. In case of updates of several LPARs, launch these updates in parallel, as each update is quite 
 long
** 13. Update in preview mode only to see what would be done.
** 14. StatusBefore and StatusAfter files for each target for all types of changes
** 15. Propose a sort of introspection mode : if manifests/init.pp is empty (and that should be 
 the case at the beginning), a 'discovery' facter (to be created) proposes the possible updates of 
 SP and iFix that could be done on all standalones existing on the NIM server, and generates the 
 manifests/init.pp.
** 16. Updating a system to a new level needs sometimes to be done twice the right level, for example
updating from 7100-04-04-1717 to 7100-05. This happens more generally if the system being updated has 
requisites to software that identify new filesets that aren't currently installed on the system.
In th particular case of updating from 7100-04-04-1717 to 7100-05, the Java filesets listed weren't 
already on the system at a downlevel. Whenever AIX ships newly defined filesets as part of a TL/SP, 
the fileset list of downlevel software (requiring an update in level) wouldn't have the unknown 
fileset names in the install list. So, customers would have to update again so the newer fileset(s) 
get applied. 
 Then the TO DO would be to detect theses case and launch twice the update when necessary 
 One complication is that the first update notifies user that a 'reboot is required' and this 
 notification is lost at second update.  

## DONE 
** 1. Suma preview is likely to be unnecessary if 'to_step' is set to 'download'. Consider skipping 
 this preview step in this case.
** 2. Display manifests/init.pp at the beginning of the log, so that we can know what is being applied.
 this is done through a new facter : applied_manifest
** 3. Better interface to display SP per TL results to user
** 4. Better display of results of factor
** 5. Better management of c_rsh rc

         
