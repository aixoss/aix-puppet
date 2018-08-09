### TO-DO LIST
 1. Automatically compute Suma downloads scope taken into account "oslevel -s" of a list of 
  targets, currently this needs to be manually set by user, by using the 'from' and the 'to' 
  parameters of 'download' custom type. This can lead to a merge of two existing custom types: 
  'download' and 'patchmngt'. Today these two clauses need to be piped one after the other one.  
 2. Propose a sort of introspection mode : if manifests/init.pp is empty (and that should be 
  the case at the beginning), a 'discovery' facter (to be created) proposes the possible updates of 
  SP and iFix that could be done on all standalones existing on the NIM server, and generates the 
  manifests/init.pp.
 3. Workaround of an 'abnormal' behaviour<br>
  Updating a system to a new level needs sometimes to be done twice the right level, for example
   updating from 7100-04-04-1717 to 7100-05. This happens more generally if the system being 
   updated has requisites to software that identify new filesets that aren't currently installed 
   on the system. In this particular case of updating from 7100-04-04-1717 to 7100-05, the Java 
   filesets listed weren't  already on the system at a downlevel. Whenever AIX ships newly defined 
   filesets as part of a TL/SP, the fileset list of downlevel software (requiring an update in 
   level) wouldn't have the unknown fileset names in the install list. So, customers would have to 
   update again so the newer fileset(s) get applied. Then the TO DO would be to detect theses case 
   and launch twice the update when necessary. One complication is that the first update notifies 
   user that a 'reboot is required' and this notification is lost at second update.
 4. Propose 'master' as target so that all operations can be done on NIM master itself.
 5. Propose to exploit 'Reboot needed' to inform user when a reboot is needed after an 
   install/update eFix.
 6. Propose to work with an offline 'apar.csv'. Currently the last 'apar.csv' is downloaded each 
  time. 
 7. Propose automatic installation of a list of eFix by providing them by their names.
 8. In case of updates of several LPARs, launch these updates in parallel, as each update is quite 
  long.
 9. StatusBefore and StatusAfter files for each target for all types of changes
 10. Propose regex in targets parameter so that we can perform operations on a list of targets 
  generated from a regex.
 11. Check updates consistency before trying, by looking at the BUILDDATE from the "oslevel -s", 
  and by comparing with BUILDDATE of the update. 
 12. Maybe not judicious ro raise exception into Automation::Lib::Suma as these exceptions are not
  caught and therefore they could interrupt execution, if thrown. 
   
    


         
