 ### Last changes documented
 #### 0.6.5
   -- Better mngt of c_rsh return codes
   -- Better messages on validating 'download' attributes
   -- NIM resource for update always deleted at beginning so that it is recreated. 
       This to prevents some cases from occurring: location has been moved 
       while NIM resource remains. 
   -- New facter 'applied_manifest' to display in logs the applied manifest: 
       manifests/init.pp
   -- Parsing of 'targets' in 'applied_manifest' facter, so that 'standalones'
       facter only works if standalone is used as target.    
   -- flrtvc NIM resource recreated each time, and not reused if it exists
   -- Change the path where flrtvc yaml files are stored. They were into 
       'root' directory indicated into './manifests/init.pp', 
       they are now under ./output/flrtvc directory.
   -- Fix custom type 'clean' attribute is changed to 'force' attribute
       If force is set to 'yes', all downloads are forced again, 
       even if the downloads existed before and were available. 
       By default force is set to 'no', meaning we keep everything.
   -- One status file per target is necessary, otherwise if several 'fix' 
       custom types, then last one overrides previous ones. Therefore we'll have 
       these files 
       ./output/flrtvc/<target>_StatusAfterEfixInstall.yml<br>
       ./output/flrtvc/PuppetAix_StatusAfterEfixRemoval_<target>.yml<br>
       ./output/flrtvc/<target>_StatusBeforeEfixInstall.yml<br>
       ./output/flrtvc/PuppetAix_StatusBeforeEfixRemoval_<target>.yml<br>
   -- Persistence of flrtvc information commmon to all targets into two files
       so that these files are taken as input at beginning of flrtvc processings
       (only if clean='no'): listoffixes_per_url.yml, lppminmax_of_fixes.yml      
 #### 0.5.5
   -- Rubocop warnings removal 
   -- Better management of downloads: for example for timeout on ftp download, 
       the failed urls are identified as being in failure, and are listed at the 
       end of download phase. If you run flrtvc a second time, after a fist time 
       which had download failures, only failed urls downloads are attempted.<br>
   -- Validation messages of custom type contain contextual messages<br> 
   -- Move all outputs into ./output directory: logs are now into 
       ./output/logs, facter results are now into ./output/facter.<br>
   -- Add 'to_step' attribute to "download" custom type, to control execution 
       of the two steps 'suma-preview' and 'suma-download' separately. 
       By setting 'to_step' to "preview", only "preview" is performed. By default 
       "download" is performed.<br> 
   -- Fix the automatic installation of "/usr/bin/flrtvc.ksh" if this 
       file is missing 
   -- Renaming of "./output/facter/sp_per_tl.yml" file to 
       "./output/facter/sp_per_tl.yml.June_2018", 
       so that this file is generated at least once after installation. This file 
       contains the matches between Technical Levels and Service Packs 
       for all releases.<br>   
