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
  You can perform download operations from FixCentral separately and see results.<br>
  You can update in preview mode only (TO BE DONE), just to see the results, 
   and decide to apply later on.
  
 As far as 'efix' operations are concerned :<br>
  You can perform all preparation steps without applying the efix ans see the results.<br>
  You can choose to apply efix later on.<br>
  You can remove all efix installed if necessary<br>
   
## Usage
### Sample of manifest : init.pp
 Some commented samples are provided in ./examples/init.pp, and should be 
  used as a starting point, to customize your ./manifests/init.pp 

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
   which are performed under 'root' directories mentionned into ./manifests/init.pp file, (ou have one 'root'
   parameter for 'download' and one 'root' directory for 'fix').  
 
### Command line    
  You can test your ./manifests/init.pp manifest by using following command lines :<br>
        puppet apply --noop --modulepath=/etc/puppetlabs/code/environments/production/modules \
          -e "include aixautomation"<br>
     or apply it without debug messages : <br>
        puppet apply --modulepath=/etc/puppetlabs/code/environments/production/modules \
          -e "include aixautomation"<br>
     or apply it with debug messages : <br>
        puppet apply  --debug --modulepath=/etc/puppetlabs/code/environments/production/modules \
          -e "include aixautomation"<br>
     or apply it with debug message and Puppet logs into a file : <br>
        puppet apply --logdest=/etc/puppetlabs/code/environments/production/modules/output/logs/PuppetApply.log \
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
       when new ./output/facter/sp_per_tl.yml file is generated.<br>
    
 
### Custom types and providers
 Three custom type and their providers constitute the aixautomation module.<br>
 All custom-types utilization are documented into ./examples/init.pp<br>
 
 #### Custom type : download (provider : suma)
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
             
 
 #### Custom type : patchmngt (provider : nimpush)
 The aim of this provider is to provide software maintenance operations on a list of LPARs 
  using NIM push mode. Everything is performed from the NIM server on which this aixautomation 
  Puppet module runs.<br>   
 This NIM push mode can use Suma downloads performed by Suma provider, as preliminary step, 
  by using into 'lpp_source' parameter the lpp_source which was created by 'suma' provider.<br>
 Software maintenance operations include : install and updates.<br>
 You'll find samples of install and update into ./manifests/init.pp.<br> 
  
    
 #### Custom type : fix (provider : flrtvc)
 The aim of this provider is to provide appropriate eFix installations using flrtvc 
  functionality to compute eFix to be installable, and NIM push functionality to install eFix.<br> 
 "root" parameter is used as download directory : it should be an ad-hoc file system dedicated to 
  download efix, keep this file system separated from the system so prevent saturation.<br>   
 List of appropriate eFix to be installed on a system is firstly computed by 'flrtvc', then checked
  against constraints and a short list of eFix of installable eFix is computed, a NIM resource 
  is then built and then applied, so that eFix are installed.<br>
 These several steps necessary to achieve this efix installation task, are performed 
  following this order : "installFlrtvc", "runFlrtvc", "parseFlrtvc", "downloadFixes", "checkFixes", 
  "buildResource", "installResource". <br>
 Executions can be stopped after any step, and this is controlled thru the 'to_step' parameter 
  into ./manifests/init.pp.<br>
 Each step persists its results into a yaml file, which can be found into 'root' directory 
  used for storing downloaded iFix.<br> 
 All yaml files can be reused between two executions, to spare time if ever the external 
  conditions have not changed, this is controlled thru the 'clean' parameter which needs 
  then to be set to 'no'. By default it is set to 'true', meaning the previously computed 
  yaml files are not used.<br>
 eFix are sorted by 'Packaging Date' before being applied, i.e. most recent first. It could 
  occur that one particular eFix prevents another one (less recent) from being installed if 
  they touch the same file.<br>
 At the end of execution of this provider, you'll find into : <br>
  - ./output/logs/PuppetAix_StatusBefore.yml : how were the LPARs before eFix installation.<br> 
  - ./output/logs/PuppetAix_StatusAfter.yml : how are the LPARs after eFix installation.<br>
        
## Limitations
 List of missing things to be documented.<br> 
 Refer to TODO.md<br>

## Development
 List of things to be done to be documented.<br> 
 Refer to TODO.md<br>

## Release Notes/Contributors/Etc. **Optional**
 Last changes documented. <br>
 0.51 :
   - fix the automatic installation of "/usr/bin/flrtvc.ksh" if this file is missing 
   - renaming of "./output/facter/sp_per_tl.yml" file to "./output/facter/sp_per_tl.yml.June_2018", 
     so that this file is generated at least once after installation. This file contains
     the matches between Technical Levels and Service Packs for all releases.      
 0.52 : 
   - add 'to_step' parameter to "download" custom type, to control execution of the two steps 
    'suma preview' and 'suma download' separately. By setting 'to_step' to "preview", only 
    "preview" is performed. By default "download" is performed. 
 0.53 : 
   - validation messages of custom type contain contextual messages 
   - move all outputs into ./output directory : logs are now into ./output/logs, facter results are 
     now into ./output/facter.    
 
