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
 Necessary efix are computed and retrieved using 'flrtvc', downloaded, kept locally (in a
  local repository on the system where this Puppet module runs), and they are kept in a way 
  they can be shared between LPARs. They are then applied on a list of LPARs, by using NIM 
  push mode : updates are performed from the NIM server whithout performing any operation 
  on the LPARs themselves, therefore without installing anything on these LPARS. 

## Setup
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
  
### Setup aixautomation
 Module aixautomation (aixautomation.tar) needs to be untarred into 
  /etc/puppetlabs/code/environments/production/modules, which is the install directory
  referred as INST_DIR below.<br>
 By untarring aixautomation.tar, you'll build INST_DIR/aixautomation directory, which is 
  referred as AIX_AUTOMATION_DIR below. 
 All relative paths below are related to this AIX_AUTOMATION_DIR directory.<br>
  
 All aixautomation Puppet setups are done through the ./manifests/init.pp file.<br>
 As a prerequisites of aixautomation Puppet module, NIM configuration between NIM server
  (on which this Puppet module runs), and the LPARs (on which software maintenance 
  operations are performed) needs to be properly set : all LPARs which can either 
  not be accessible thru a simple 'ping -c1 -w5 <lpar>' command or thru a 
  simple 'c_rsh' command will be excluded from the list of targets on which 
  ./manifests/init.pp will be applied. <bt>
      
 List of lpars on which rules can be applied is retrieved thru NIM server by 
  getting list of standalones.<br>
 For advanced users who know 'ruby' language : if this list of standalones 
  is too large, and to spare time, you can skip some standalones by manually 
  editing ./aixautomation/lib/factor/standalones.rb : search for 'To shorten 
  execution', and use sample of code to perform the same logic.  
 
### What aixautomation affects 
 This module requires available disk space to store updates downloaded from FixCentral, 
  and to store downloaded eFix. By default downloads are performed into '/tmp', but a 
  more appropriate directory needs to be set into ./manifests/init.pp ('root' parameter 
  of 'download' clause). File system on which downloads are performed is automatically 
  increased (100 MB each time) if necessary (if system allows).<br>
 This module will perform software updates of your systems, and install (or remove) 
  eFix.  

### Setup Requirements 
 This module requires that the LPAR which are targeted to be updated are managed by 
  the same NIM server than the one on which Puppet runs.
 
### Beginning with aixautomation
 As a starter, you can only perform a status, which will display the 'oslevel -s' 
  result and 'lslpp -l' results of command on the list of LPAR you want to update. 
  
 As far as 'update' operation are concerned :<br> 
  You can perform download operations from FixCentral separately and see results.<br>
  You can update in preview mode only, just to see the results, and decide to apply 
   later on.
  
 As far as 'efix' operations are concerned :<br>
  You can perform all preparation steps without applying the efix ans see the results<br>
  You can choose to apply efix later on <br>
  You can remove all efix installed if necessary<br>
   
## Usage
### Sample of manifest : init.pp
 A large number of commented samples are provided in ./examples/init.pp, and should be 
  used as a starting point, to customize your ./manifests/init.pp 

### Logs
 The Puppet.debug('message') method is used in Puppet framework and as well in aixautomation 
  and these debug messages can be seen with the use of Puppet "--debug" flag on the command line.<br> 
  All other level ("info", "warning", "error") are displayed without condition.<br>   
 These Puppet log messages are displayed on console output.<br> 
 You can redirect all Puppet output to one file with the use of Puppet "--logdest=logfile.txt" on 
  the command line. 
 
 AixAutomation logs (and only AixAutomation log, and not Puppet log) are generated into 
   ./logs/PuppetAixAutomation.log.<br>
  Up to 12 rotation log files of one 1 MB are kept : ./logs/PuppetAixAutomation.log.0
   to ./logs/PuppetAixAutomation.log.12<br>
  These logs does not depend from Puppet --debug flag on the command line, and you'll get them 
   in any case.
 
### Installation directory 
  As said already, aixautomation module is installed into /etc/puppetlabs/code/environments/production/modules :<br> 
   /etc/puppetlabs/code/environments/production/modules/aixautomation, and all relative paths below
   are relative to /etc/puppetlabs/code/environments/production/modules/aixautomation.<br>
  The aixautomation module generates all outputs under this directory, except downloads of updates and ifixes 
   which are performed under 'root' directory mentionned into ./manifests/init.pp file.  
 
### Command line    
  You can apply your ./manifests/init.pp manifest by using following command lines :<br>
        puppet apply --noop --modulepath=/etc/puppetlabs/code/environments/production/modules \
          -e "include aixautomation"<br>
     or : <br>
        puppet apply  --debug --modulepath=/etc/puppetlabs/code/environments/production/modules \
          -e "include aixautomation"<br>
     or : <br>
        puppet apply --logdest=/etc/puppetlabs/code/environments/production/modules/logs/PuppetApply.log \
         --debug --modulepath=/etc/puppetlabs/code/environments/production/modules \
         -e "include aixautomation"<br>   
        Please note that if you use "--logdest" parameter, you won't see any output on the 
         command line as everything is redirected to log file.
            
## Reference
### Facters
 Specific aixautomation facters collect the necessary data enabling 
  aixautomation module to run :<br> 
    - props : to have shared configuration properties.<br>
    - standalones : you'll find results on this factor into ./facter/standalones_kept.yml file, 
       and into ./facter/standalones_skipped.yml file.<br>
    - (preparation for) vios  : you'll find results on this factor into ./facter/vios_kept.yml file, 
       and into ./facter/vios_skipped.yml file.<br> 
    - servicepacks : you'll find results on this factor into ./facter/sp_per_tl.yml file, if this 
       file does not exist, it is computed by automatically downloading Suma metadata files, all 
       Suma metadata files are temporarily downloaded under ./facter/suma, but are removed at the end, 
       when new ./facter/sp_per_tl.yml file is generated.<br>
 
### Custom types and providers
 Three custom type and their providers constitute the aixautomation module.<br>
 All custom-types are documented into ./examples/init.pp<br>
 
 #### Custom type : download (provider : suma)
 The aim of this provider is to provide download services using suma functionality.<br>
 Suma requests are generated so that updates are downloaded from Fix Central.<br>
 Suma metadata are downloaded if ever they are not locally present into './facter/sp_per_tl.yml'  
  file : this file gives for each possible technical level the list of available service packs.<br> 
  It is a good practice to consider that the './facter/sp_per_tl.yml' delivered is maybe
   not up-to-date, and therefore let 'suma' provider downloads metadata 'in live' 
   and compute last './facter/sp_per_tl.yml'. To perform this, you can rename 
   './facter/sp_per_tl.yml' to './facter/sp_per_tl.yml.saved' so that this './facter/sp_per_tl.yml' 
   is computed again. <br>
 Various types of suma downloads can be performed : either "SP", or "TL", or "Latest" :<br>
  - "SP" contains everything update system on a given Technical Level.<br>
  - "TL" contains everything to update system from a Technical Level to another 
    Technical Level.<br>
  - "Latest" contains everything to update system to the last Service pack of a given 
    Technical Level.<br>
 
 #### Custom type : patchmngt (provider : nimpush)
 The aim of this provider is to provide software maintenance operations on a list of LPARs 
  using NIM push mode. Everything is performed from the NIM server on which this aixautomation 
  Puppet module runs.<br>   
 This NIM push mode can use suma downloads performed by Suma provider, as preliminary step.<br>
 Software maintenance operations include : install and updates<br>
    
 #### Custom type : fix (provider : flrtvc)
 The aim of this provider is to provide appropriate eFix installations using flrtvc functionality.<br> 
 "Root" parameter is used as download directory : tt should be an ad hoc file system dedicated to 
  download data, keep this file system separated from the system so prevent saturation.   
 List of appropriate eFix to be installed on a system is computed, and eFix are installed.<br>
 Several steps are necessary to achieve this efix installation task, and they are performed 
  following this order : "runFlrtvc", "parseFlrtvc", "downloadFixes", "checkFixes", 
  "buildResource", "installResource". <br>
 Executions can be stopped after any step, and this is controlled thru the 'to_step' parameter 
  into ./manifests/init.pp.<br>
 Each step persists its results into a yaml file, which can be found into 'root' directory 
  used for storing downloaded iFix.<br> 
 All yaml file can be reused between two execution, to spare time if ever the external 
  conditions have not changed, this is controlled thru the 'clean' parameter which needs 
  then to be set to 'no'. By default it is set to 'true'.<br>
 eFix are sorted by 'Packaging Date' before being applied, i.e. most recent first. It could 
  occur that one particular eFix prevents another one (less recent) from being installed if 
  they touch the same file.<br>      
        
## Limitations
 List of missing things to be documented.<br> 
 Refer to TODO.md<br>

## Development
 List of things to be done to be documented.<br> 
 Refer to TODO.md<br>

## Release Notes/Contributors/Etc. **Optional**
 Last changes to be documented. <br>
