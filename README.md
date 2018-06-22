# Puppet AixAutomation

#### Table of Contents

1. [Description](#description)
1. [Setup - The basics of getting started with aixautomation](#setup)
    * [What aixautomation affects](#what-aixautomation-affects)
    * [Setup requirements](#setup-requirements)
    * [Beginning with aixautomation](#beginning-with-aixautomation)
1. [Usage - Configuration options and additional functionality](#usage)
1. [Reference - An under-the-hood peek at what the module is doing and how](#reference)
1. [Limitations - OS compatibility, etc.](#limitations)
1. [Development - Guide for contributing to the module](#development)

## Description
 This aixautomation Puppet module has been developed against Puppet 5.3.3, and has been 
  tested against Puppet 5.3.3 and Puppet 5.3.5.<br>  
 This aixautomation Puppet module enables automation of software maintenance operations 
  on a list of AIX LPARs, by running this module on a NIM server managing these LPARs.<br>
 By software maintenance operations we mean : updates of AIX levels, updates of efix.<br>   
 Necessary AIX level updates are automatically downloaded from FixCentral using 'suma' 
  functionalities, and are locally kept and shared between LPARs if possible.<br>
 Updates can be automatically applied on a list of LPARs, through 'nim push' operation, 
  therefore everything runs from the NIM server, and nothing needs to be installed on 
  LPARs themselves.<br>
 List of necessary efix is computed (per each LPAR) and retrieved using 'flrtvc', 
  downloaded, kept locally (in a local repository on the system where this Puppet module 
  runs), and they are kept in a way they can be shared between LPARs. Each LPAR has its 
  own list of efix to be applied, depending on its level, the current list of efix already 
  applied. Theses efix are then applied on each LPAR of the list (after being sorted 
  by 'PACKAGING DATE' : so that most recent are applied first), by using NIM push mode : 
  updates are performed from the NIM server without performing any operation on the 
  LPARs themselves, therefore without installing anything on these LPARs. 

## Setup
### Setup Requirements 
 This aixautomation module requires that the LPARs which are targeted to be updated 
  are managed by the same NIM server than the one on which Puppet runs. <br>
 This aixautomation module requires download access to FixCentral, and http/https/ftp 
  access to eFix download server.<br>  
 
### Setup Puppet 
 First of all, you'll need to install Puppet on your NIM server. <p>
 To run this aixautomation module, you only need Puppet running in a standalone way. <br>
 Download Puppet 5.3 from https://puppet.com/download-puppet-enterprise :<br> 
  **- for AIX 7.2,7.1** : https://s3.amazonaws.com/puppet-agents/2017.3/puppet-agent/5.3.5/repos/aix/7.1/PC1/ppc/puppet-agent-5.3.5-1.aix7.1.ppc.rpm<br>
  **- for AIX 6.1** : https://s3.amazonaws.com/puppet-agents/2017.3/puppet-agent/5.3.5/repos/aix/6.1/PC1/ppc/puppet-agent-5.3.5-1.aix6.1.ppc.rpm<br>
 Puppet rpm is installed using rpm -i command line.<br>  
 After Puppet installation, path to puppet is /opt/puppetlabs/puppet/bin/puppet.<br>
 Please note that Puppet comes with its own ruby, you'll find it here after Puppet installation :<br> 
    "/opt/puppetlabs/puppet/bin/ruby -version" returns "ruby 2.4.2p198 (2017-09-14 revision 59899)" 
  
### Setup aixautomation module
 Module aixautomation (aixautomation.tar) needs to be untarred into 
  /etc/puppetlabs/code/environments/production/modules, which is the install directory
  referred as INST_DIR below.<br>
 By untarring aixautomation.tar, you'll build INST_DIR/aixautomation directory, which is 
  referred as AIX_AUTOMATION_DIR below. 
 <b>All relative paths below are related to this AIX_AUTOMATION_DIR directory.</b><br>
  
 All aixautomation module setups are done through the ./manifests/init.pp file.<br>
 As a prerequisites of aixautomation Puppet module, NIM configuration between NIM server
  (on which this Puppet module runs), and the LPARs (on which software maintenance 
  operations are performed) needs to be properly set : all LPARs which can either 
  not be accessible thru a simple 'ping -c1 -w5 <lpar>' command or thru a 
  simple 'c_rsh' command will be excluded from the list of targets on which 
  ./manifests/init.pp will be applied. <br>
      
 List of LPARs on which rules can be applied is retrieved thru NIM server by 
  getting list of standalones.<br>
 For advanced users who know 'ruby' language : if this list of standalones 
  is too large, and to spare time, you can skip some standalones by manually 
  editing ./aixautomation/lib/factor/standalones.rb : search for 'To shorten 
  execution', and use sample of code to perform the same logic of white list,
  or black list.  
 
### What aixautomation module affects 
 This module requires available disk space to store updates downloaded from FixCentral, 
  and to store downloaded eFix. By default downloads are performed into '/tmp', but a 
  more appropriate directory needs to be set into ./manifests/init.pp ('root' parameter 
  of 'download' clause for AIX updates, and 'root' parameter of 'fix' clause for efix). 
  File system on which downloads are performed is automatically increased (100 MB each 
  time) if necessary (if system allows).<br>
 This module will perform AIX software updates of your systems, and install (or remove) 
  eFix.  

### Beginning with aixautomation
 As far as 'update' operation are concerned :<br> 
  You can perform download operations from FixCentral (suma downloads) and build a NIM 
  lpp_source resource with results of downloads in a first separate step, then in a second
   step you can update LPARs using the NIM lpp_source resource which was downloaded.    
 As far as 'efix' operations are concerned :<br>
  You can perform all preparation steps without applying the efix ans see the results.<br>
  You can choose to apply efix later on.<br>
  You can remove all efix installed if necessary<br>
   
## Usage
### Sample of manifest : init.pp
 Some commented samples are provided in ./examples/init.pp, and should be 
  used as a starting point, to customize ./manifests/init.pp 

### Logs
 The Puppet.debug('message') method is used in Puppet framework and as well in aixautomation 
  and these debug messages can be seen with the use of Puppet "--debug" flag on 
  the command line.<br> 
  All other level ("info", "warning", "error") are displayed without condition.<br>   
 These Puppet log messages are displayed on console output.<br> 
 You can redirect all Puppet output to one file with the use of Puppet 
  "--logdest=/etc/puppetlabs/code/environments/production/modules/output/logs/logfile.txt" on 
  the command line. 
 
 AixAutomation logs (and only AixAutomation log, and not Puppet log) are generated into 
   ./output/logs/PuppetAixAutomation.log.<br>
  Up to 12 rotation log files of one 1 MB are kept : ./output/logs/PuppetAixAutomation.log.0
   to ./output/logs/PuppetAixAutomation.log.12<br>
  These logs does not depend from Puppet --debug flag on the command line, and you'll get them 
   in any case.
 
### Installation directory 
  As said already, aixautomation module is installed into /etc/puppetlabs/code/environments/production/modules :<br> 
   /etc/puppetlabs/code/environments/production/modules/aixautomation, and all relative paths in this README 
   are relative to /etc/puppetlabs/code/environments/production/modules/aixautomation.<br>
  The aixautomation module generates all outputs under this directory, except downloads of updates and ifixes 
   which are performed under 'root' directories mentioned into ./manifests/init.pp file, (ou have one 'root'
   parameter for 'download' and one 'root' directory for 'fix').  
 
### Command line    
  You can test ./manifests/init.pp manifest by using following command lines :<br>
        /opt/puppetlabs/puppet/bin/puppet apply \ 
          --noop --modulepath=/etc/puppetlabs/code/environments/production/modules \
          -e "include aixautomation"<br>
     or apply it without debug messages : <br>
        /opt/puppetlabs/puppet/bin/puppet apply \
          --modulepath=/etc/puppetlabs/code/environments/production/modules \
          -e "include aixautomation"<br>
     or apply it with debug messages : <br>
        /opt/puppetlabs/puppet/bin/puppet apply  --debug \ 
        --modulepath=/etc/puppetlabs/code/environments/production/modules \
          -e "include aixautomation"<br>
     or apply it with debug message and Puppet logs into a file : <br>
        /opt/puppetlabs/puppet/bin/puppet apply \ 
         --logdest=/etc/puppetlabs/code/environments/production/modules/output/logs/PuppetApply.log \
         --debug --modulepath=/etc/puppetlabs/code/environments/production/modules \
         -e "include aixautomation"<br>   
        Please note that if you use "--logdest" parameter, you won't see any output on the 
         command line as everything is redirected to log file.
            
## Reference
### Facters
 Specific aixautomation facters collect the necessary data enabling aixautomation module to run :<br> 
    - props : to have shared configuration properties.<br>
    - standalones : you'll find results on this factor into ./output/facter/standalones_kept.yml file, 
       and into ./output/facter/standalones_skipped.yml file. This 'standalones' facter takes some time at 
       the beginning of aixautomation module, but as explained above, you have the possibility to manage 
       white list or black list of standalones to shorten execution.<br>
    - (preparation for) vios  : you'll find results on this factor into ./output/facter/vios_kept.yml file, 
       and into ./output/facter/vios_skipped.yml file.<br> 
    - servicepacks : you'll find results on this factor into ./output/facter/sp_per_tl.yml file, if this 
       file does not exist, it is computed by automatically downloading Suma metadata files, all 
       Suma metadata files are temporarily downloaded under ./output/facter/suma, but are removed at the end, 
       when new ./output/facter/sp_per_tl.yml file is generated. Please note that as part of this computing,
       metadata downloads are attempted for SP of each TL until repeatedly errors occur, meaning that the last 
       SP do not exist. Therefore it is normal to have errors when we reach non-existing SP, this is the way 
       which is used to go until last existing SP.  
        
    
 
### Custom types and providers
 Three custom type and their providers constitute the aixautomation module.<br>
 All custom-types utilization are documented into ./examples/init.pp<br>
 
 #### Custom type : download (provider : suma)
 ##### Parameters
   - <b>provider</b> : this parameter is not mandatory, if mentioned it needs to contain name of 
   the provider implementing the 'download' custom type, therefore the value needs to be : <b>suma</b>.  
   - <b>ensure</b> : to control flow of execution, this parameter can take two values, either 
   <b>present</b> or <b>absent</b>. By default <b>present</b> is assumed. 
   If set the <b>present</b>, suma command will be attempted so that what is set into parameters is 
    performed.
   If set to <b>absent</b>, result of previous <b>present</b> run is clean : NIM lpp_source resource 
    is cleaned, and results of suma downloads is removed from disks.     
   - <b>name</b> : not a mandatory property if you have only one 'download' clause in 
   ./manifests/init.pp. Otherwise (multiple 'download' clauses), this property is necessary  
   to uniquely identify the download to be performed : you can have several 'download' 
   clauses in ./manifests/init.pp, each of them being uniquely identified. 
   - <b>root</b> : root directory to store results of suma download. This root directory should reside 
   on a file system separated from the one which hosts the system itself. This root directory needs 
   to be large enough to contain system updates, and should be a exportable file system, so that NIM 
   can build NIM lpp_source resource and perform a mount from the remote LPARs.      
   - <b>type</b> : type of suma downloads. Three possible values : <b>SP</b> to suma download a service 
   pack, i.e. what allows you to update from a XXXX-YY technical level to any service packs of this 
   technical level. <b>TL</b> to suma download a technical level, so that you system gets updated 
   to a new technical level. <b>Latest</b> to suma download the last service pack of a given technical
    level.  A last possible value is possible : <b>Meta</b> but is reserved for internal use.   
   - <b>from</b> : parameter used to launch suma download command, containing the starting level 
   of desired updates. For example by indicating <b>7100-01</b>, it means download contains everything 
   to update from this <b>7100-01</b> technical level, or  by indicating <b>100-01-02-1150</b>, it 
   means download contains everything to update from this <b>7100-01-02-1150</b> service pack.
   - <b>to</b> : parameter used to launch suma download command, containing the level of updates 
   desired. For example by indicating <b>7100-03</b>, it means download contains everything to 
   update up to this <b>7100-03</b> technical level, or  by indicating <b>7100-01-08-1642</b>, it 
   means download contains everything to update up to this <b>7100-01-08-1642</b> service pack.
   - <b>lpp_source</b> : name of the NIM lpp_source resource built containing results of suma 
   downloads. If ever this lpp_source name is not provided, a naming convention is used to build 
   this name, by using a prefix ('PAA'), and by concatenating 'type', 'from', and 'to' parameters. 
   The name of this lpp_source is reused when performing updates of system (using 'nimpush' clause).  
   - <b>to_step</b> : to control flow of execution up to a given step. Two possible steps : 
   <b>preview</b> and <b>download</b>. By default, <b>download</b> is assumed. You can perform 
   only <b>preview</b> suma download, by setting this parameter to <b>preview</b>, in that case 
   download is not done.
   - <b>force</b> : to force suma download again. Two possible values for this parameter : 
   <b>yes</b> and <b>no</b>. By default, <b>no</b> is assumed, meaning that suma download won't be 
   done again if expected results of suma download can be found under <b>root</b> directory. 
   If set to <b>yes</b>, this parameter can force a new suma download (even if this suma download 
   was already done, and can be found under <b>root</b> directory) and can force the building of a 
   new NIM lpp_source resource (even if this NIM lpp_source resource already exists). 
##### Explanations
 The aim of this provider is to provide download services using suma functionality.<br>
 Suma requests are generated so that updates are downloaded from Fix Central.<br>
 "root" parameter is used as download directory : it should be an ad-hoc file system dedicated to 
  download updates, keep this file system separated from the system so prevent saturation.<br>   
 At a preliminary step, suma <b>metadata</b> are downloaded if ever they are not locally 
  present into './output/facter/sp_per_tl.yml' file : this file gives for each possible technical 
  level the list of available service packs.<br> 
 It is a good practice to consider that the './output/facter/sp_per_tl.yml' delivered is maybe
  not up-to-date, and therefore let 'suma' provider downloads metadata 'in live' 
  and compute a more recent version of './output/facter/sp_per_tl.yml'. To perform this, you can rename 
  './output/facter/sp_per_tl.yml' to './output/facter/sp_per_tl.yml.saved' so that this 
  './output/facter/sp_per_tl.yml' is computed again. You should perform this operation once in a 
  while (every month or so).<br>
 Various types of suma downloads can be performed : either "SP", or "TL", or "Latest" :<br>
  - "SP" contains everything update system on a given Technical Level.<br>
  - "TL" contains everything to update system from a Technical Level to another 
    Technical Level.<br>
  - "Latest" contains everything to update system to the last Service Pack of a given 
    Technical Level.<br>
 As a result of suma download a lpp_source NIM resource is built. You can choose either 
  to name it (with your own way of naming), or let 'suma' provider name the lpp_source.
  Naming convention use "PAA" as a prefix to identify automatically lpp_source NIM resource
   as a shortcut for "<b>P</b>uppet<b>A</b>ix<b>A</b>utomation"'. Then the <type> of suma 
   download is used : "SP", "TL", "Latest", then the <from> and the <to> fields. As a example, 
   you would have : "PAA_SP_7100-03_7100-03-07-1614" indicating a NIM resource to update from 
   7.3.0 to 7.3.7.1614 SP.
 It is possible to perform only the suma 'preview' (and therefore not the suma 'download')
   by setting the 'to_step' parameter of the download custom type to 'preview'. By default, this
   'to_step' parameter is set to 'download', meaning that the suma download is performed. 
 One new parameter 'force' enables to force downloads of everything from scratch, even if 
   the results of downloads are available. Set this 'force' parameter to 'yes' to force 
   downloads again. In that case 'preview' is done only if explicitly required. 
   By default 'force is set to 'no', meaning all previous downloads are kept and reused, this 
   can spare a lot of time.   
 #### Custom type : patchmngt (provider : nimpush)
 ##### Parameters
   - <b>provider</b> : this parameter is not mandatory, if mentioned it needs to contain name of 
   the provider implementing the 'patchmngt' custom type, therefore the value needs to be : 
   <b>nimpush</b>.  
   - <b>ensure</b> : to control flow of execution, this parameter can take two values, either 
   <b>present</b> or <b>absent</b>. By default <b>present</b> is assumed. 
   If set the <b>present</b>, nim push command will be attempted so that what is set 
   into parameters is performed.
   If set to <b>absent</b>, .     
   - <b>name</b> : to uniquely identify the download to be performed. You can have 
   several 'patchmngt' clauses in ./manifests/init.pp, each of them being uniquely 
   identified. 
  - <b>action</b> : action to be performed. This parameter can take several values : <b>install</b>, 
   <b>update</b>, <b>reboot</b>, <b>status</b>. By default, <b>status</b> is assumed.
   <b>install</b> action enables installation (or un-installation) of a lpp_source, <b>update</b> 
   action enables update of a system (installation of a service pack or installation of a technical
   level), <b>reboot</b> action enables to launch reboot of LPARs. <b>status</b> action displays
   version level and efix information related to LPARs.       
  - <b>lpp_source</b> : name of the NIM lpp_source resource to be installed/un-installed or which needs to be 
  used to performed system update. In case of update, this lpp_source is the one which was built by 
  a previous 'download' clause (results of suma downloads). 
  - <b>targets</b> : names of the LPARs on which to perform action
  - <b>sync</b> : if action needs to be done synchronously or asynchronously. Two possible values for this 
  parameter : <b>yes</b> and <b>no</b>. By default, <b>no</b> is assumed.  
 ##### Explanations
 The aim of this provider is to provide software maintenance operations on a list of LPARs 
  using NIM push mode. Everything is performed from the NIM server on which this aixautomation 
  Puppet module runs.<br>   
 This NIM push mode can use Suma downloads performed by Suma provider, as preliminary step, 
  by using into 'lpp_source' parameter the lpp_source which was created by 'suma' provider.<br>
 Software maintenance operations include : install and updates.<br>
 You'll find samples of install and update into ./manifests/init.pp.<br> 
  
    
 #### Custom type : fix (provider : flrtvc)
 ##### Parameters
   - <b>provider</b> : this parameter is not mandatory, if mentioned it needs to contain name of 
   the provider implementing the 'fix' custom type, therefore the value needs to be : 
   <b>flrtvc</b>.  
   - <b>ensure</b> : to control flow of execution, this parameter can take two values, either 
   <b>present</b> or <b>absent</b>. By default <b>present</b> is assumed. 
   If set the <b>present</b>, efix are installed by running all steps. If set to <b>absent</b>, 
   efix are removed.     
   - <b>name</b> : to uniquely identify the fix to be performed. You can have 
   several 'fix' clauses in ./manifests/init.pp, each of them being uniquely 
   identified. 
   - <b>to_step</b> : : to control flow of execution up to a given step. Possible values : 
   <b>installFlrtvc</b>, <b>runFlrtvc</b>, <b>parseFlrtvc</b>, <b>downloadFixes</b>, 
   <b>checkFixes</b>, <b>buildResource</b>, <b>installResource</b>. All these steps are 
   performed in the provided order, but you can interrupt execution afetr any given step. 
   By default, <b>installResource</b> is assumed, meaning all steps are done. You can 
   perform flrtvc execution until the step you choose, by setting this parameter to 
   the desired step. 
   - <b>targets</b> : names of the LPARs on which to perform flrtvc steps.
   - <b>force</b>  : to force all flrtvc steps to be done again. Two possible values for this 
   parameter : <b>yes</b> and <b>no</b>. By default, <b>yes</b> is assumed, meaning all previous 
   results of any flrtvc runs (which are persisted into yaml files) are not kept, and 
   computed again. If ever you want to spare time, and reuse previous flrtvc results, or if you 
   want or run flrtvc step by step (refer to <b>to_step</b> parameter), you can keep previous results 
   by setting this parameter to <b>no</b>. 
   - <b>root</b> : root directory to store results of flrtvc download. This root directory should 
   reside on a file system separated from the one which hosts the system itself. This root 
   directory needs to be large enough to contain efix updates, and should be a exportable file 
   system, so that NIM can build NIM lpp_source resource and perform a mount from the remote LPARs.
   By default <b>/tmp</b> is assumed. 
   - <b>type</b> : type of desired efix. Possible values : <b>hiper</b>, <b>sec</b>, <b>all</b>. By default,
   <b>all</b> is assumed, meaning all possible efix are installed.       
 ##### Explanations
 The aim of this provider is to provide appropriate eFix installations using flrtvc 
  functionality to compute eFix to be installable, and NIM push functionality to install eFix.<br> 
 "root" parameter is used as download directory : it should be an ad-hoc file system dedicated to 
  download efix, keep this file system separated from the system so prevent saturation.<br>   
 List of appropriate eFix to be installed on a system is firstly computed by 'flrtvc', then checked
  against constraints and a short list of eFix of installable eFix is computed, a NIM resource 
  is then built and then applied, so that eFix are installed.<br>
 These several steps necessary to achieve this efix installation task, are performed 
  following this order : "installFlrtvc", "runFlrtvc", "parseFlrtvc", "downloadFixes", 
  "checkFixes", "buildResource", "installResource". <br>
 Executions can be stopped after any step, and this is controlled thru the 'to_step' parameter 
  into ./manifests/init.pp.<br>
 Each step persists its results into a yaml file, which can be found into 
  ./aixautomation/output/flrtvc directory.<br> 
 All yaml files can be reused between two executions, to spare time if ever the external 
  conditions have not changed, this is controlled thru the 'clean' parameter which needs 
  then to be set to 'no'. By default it is set to 'true', meaning the previously computed 
  yaml files are not used.<br>
 eFix are sorted by 'Packaging Date' before being applied, i.e. most recent first. It could 
  occur that one particular eFix prevents another one (less recent) from being installed if 
  they touch the same file.<br>
 At the end of execution of this provider, you'll find into : <br>
  - ./aixautomation/output/logs/PuppetAix_StatusBefore_<target>.yml : how were the <target> 
    LPAR before eFix installation.<br> 
  - ./aixautomation/output/logs/PuppetAix_StatusAfter_<target>.yml : how are the <target> 
    LPARs after eFix installation.<br>
        
## Limitations
 List of missing things to be documented.<br> 
 Refer to TODO.md<br>

## Development
 List of things to be done to be documented.<br> 
 Refer to TODO.md<br>

## Release Notes/Contributors/Etc. **Optional**
 ### Last changes documented
 #### 0.5.1:
   - fix the automatic installation of "/usr/bin/flrtvc.ksh" if this file is missing 
   - renaming of "./aixautomation/output/facter/sp_per_tl.yml" file to 
     "./aixautomation/output/facter/sp_per_tl.yml.June_2018", 
     so that this file is generated at least once after installation. This file contains
     the matches between Technical Levels and Service Packs for all releases.<br>      
 #### 0.5.2:
   - add 'to_step' parameter to "download" custom type, to control execution of the two steps 
    'suma preview' and 'suma download' separately. By setting 'to_step' to "preview", only 
    "preview" is performed. By default "download" is performed.<br> 
 #### 0.5.3:
   - validation messages of custom type contain contextual messages<br> 
   - move all outputs into ./aixautomation/output directory : logs are now into 
   ./aixautomation/output/logs, facter results are now into ./aixautomation/output/facter.<br>
 #### 0.5.4:
   - add status before and after ifix removal, as these status exist before and after ifix 
    installation. Commonnalize status output persistance into Flrtvc.step_status
    method.<br>
    These files can be found:<br> 
     ./aixautomation/output/logs/PuppetAix_StatusAfterInstall.yml<br>
     ./aixautomation/output/logs/PuppetAix_StatusAfterRemoval.yml<br>
     ./aixautomation/output/logs/PuppetAix_StatusBeforeInstall.yml<br>
     ./aixautomation/output/logs/PuppetAix_StatusBeforeRemoval.yml<br>
   - better management of downloads : for example for timeout on ftp download, the failed urls
    are identified as being in failure, and are listed at the end of download phase. If you run
    flrtvc a second time, after a fist time which had download failures, only failed urls
    downloads are attempted.<br>
 #### 0.5.5:
   - Rubocop warnings removal 
 #### 0.5.6:
   Several bugs fixed : 
   - One status file per target is necessary, otherwise if several 'fix' clauses, then last one 
     overrides previous ones. Therefore we'll have these files 
     ./aixautomation/output/logs/PuppetAix_StatusAfterInstall_<target>.yml<br>
     ./aixautomation/output/logs/PuppetAix_StatusAfterRemoval_<target>.yml<br>
     ./aixautomation/output/logs/PuppetAix_StatusBeforeInstall_<target>.yml<br>
     ./aixautomation/output/logs/PuppetAix_StatusBeforeRemoval_<target>.yml<br>
   - Persistence of flrtvc information commmon to all targets into two files
       so that these files are taken as input at beginning of flrtvc processings
       (only if clean='no') : listoffixes_per_url.yml, lppminmax_of_fixes.yml      
   - 'nimpush' targets are now reset between each 'nimpush' clause info ./manifests/init.pp
      this was not the case previously, and brought a lot of confusion when several 'nimpush'
      clauses, applying on different sets of targets, existed into ./manifests/init.pp.
 #### 0.5.7
   - Rubocop warnings removal 
   - fix custom type 'clean' parameter is changed to 'force' parameter
     If force is set to 'yes', all downloads are forced again, even if the downloads 
      existed before and were available. By default force is set to 'no', meaning we keep 
      everything.
 #### 0.5.8
   - Again Rubocop warnings removal 
   - Robustify suma error paths: better flow of exceptions and errors
   - Change the path where flrtvc yaml files are stored. They were into 'root' directory indicated
     into ./manifests/init.pp, they are now under ./aixautomation/output/flrtvc direcory.
  #### 0.5.9        
   - flrtvc NIM resource rebuilt each time, and not reused if it exists
   - better logs in flrtvc flow
        
 ### Debugguing tips
 If ever you have in your environment this variable set : 'ENV=/.kshrc', this can lead to abnormal 
 behaviour, not well explained. In that case, perform 'unset ENV' before retrying.
 
      
       
    
     
