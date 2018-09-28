# Puppet AixAutomation

#### Table of Contents

1. [Description](#description)
2. [Setup - The basics of getting started with aixautomation](#setup)
    * [What aixautomation affects](#What-AixAutomation-module-affects)
    * [Setup requirements](#setup-requirements)
    * [Beginning with aixautomation](#beginning-with-aixautomation)
3. [Usage - Configuration options and additional functionality](#usage)
4. [Reference - An under-the-hood peek at what the module is doing and how](#reference)
5. [Limitations - OS compatibility, etc.](#limitations)
6. [Development - Guide for contributing to the module](#development)

## Description
 This Puppet AixAutomation module has been developed against Puppet 5.3.3, and 
 has been tested against Puppet 5.3.3 and Puppet 5.3.5.<br>
 This Puppet AixAutomation module runs by using the '**puppet apply**' command, 
  therefore this is not the canonical way of using Puppet: no Puppet master, 
  no node executing Puppet agent. With Puppet AixAutomation module, 
  a unique Puppet Agent needs to run on the host where the NIM server runs.<br>    
 This Puppet AixAutomation module enables automation of software maintenance 
  operations (updates of AIX or VIOS levels, updates of eFix) on a list of 
  AIX LPARs and AIX VIOS, by running this module on a NIM server managing 
  these LPARs and VIOS.<br>
 Operations desired by the user are declared into a manifest file, using Puppet
  configuration language called DSL (Domain Specific Language), and using  
  ad hoc syntax explained below. This syntax uses specific custom types that 
  have been implemented (with their related providers) for Puppet AixAutomation
   module, to control necessary operations to automatically perform AIX updates 
   and patch management. These new custom types enable to declare resources in 
   manifest file. These types '**download**', '**patchmngt**', '**fix**', and 
   '**vios**' are described hereafter in detail.<br>
 AIX updates and patch management operations performed by this AixAutomation 
  Puppet module are shortly described now.<br><br>
  **Firstly** as far as AIX LPARs are concerned:<br>          
 - Necessary AIX level updates are automatically downloaded from FixCentral 
  using '**suma**' features. Downloaded updates are locally kept and shared 
  between LPARs if possible.<br>
 - Downloaded updates can then be automatically applied on a list of LPARs, 
  through '**NIM push**' operations, therefore everything (i.e. all 
  AixAutomation logic) runs from the NIM server, and nothing needs to be 
  installed on LPARs themselves.<br>
 - List of necessary eFix is computed (for each LPAR) and retrieved using 
  '**flrtvc**', downloaded, kept locally (in a local repository of the 
  system where this Puppet module runs), and they are kept in a way 
  they can be shared between LPARs. Each LPAR has its own list of eFix 
  to be applied, depending on its level and depending on the current list 
  of eFix already applied. <br> 
  These eFix are then applied on each LPAR of the list (after being sorted 
  by 'PACKAGING DATE': so that most recent ones are applied first). Moreover, 
  before attempting the eFix installations, a 'fileset interlock' check removes
  from the list of eFix to be installed any eFix presenting a foreseen fileset 
  interlock with any other more recent eFix. <br>
  This eFix apply operation is done by using '**NIM push**' operations 
  (therefore as already said without performing any operation on the 
  LPARs themselves: without installing anything on these LPARs).<br><br>
  **Secondly** as far as AIX VIOS are concerned:<br>
 - VIOS updates can be automatically applied on a list of VIOS, 
  by using '**NIM push**' operations. As for LPARs updates, everything (i.e. all 
  AixAutomation logic) runs from the NIM server, and nothing needs to be 
  installed on VIOS themselves.<br> 
  To bring trust in VIOS update operation, a mandatory copy of rootvg is taken 
  before performing update, and AIXAutomation logic takes into account the 
  potential mirroring of rootvg, and possible SSP cluster membership. 
  See more explanations below. 
   
## Setup
### Setup Requirements 
 This AixAutomation module needs to run a the NIM server which manages LPARs 
 to be updated, therefore Puppet needs to be installed and run on this NIM server. <br>
 This AixAutomation module requires download access to FixCentral, and http/https/ftp 
  access to eFix download server.<br>  
 
### Setup Puppet 
 First of all, you'll need to install Puppet on your NIM server. <p>
 To run this AixAutomation module, you only need Puppet running in a standalone way. <br>
 Download Puppet 5.3 from https://puppet.com/download-puppet-enterprise:<br> 
  **- for AIX 7.2, 7.1**: https://s3.amazonaws.com/puppet-agents/2017.3/puppet-agent/5.3.5/repos/aix/7.1/PC1/ppc/puppet-agent-5.3.5-1.aix7.1.ppc.rpm<br>
  **- for AIX 6.1**: https://s3.amazonaws.com/puppet-agents/2017.3/puppet-agent/5.3.5/repos/aix/6.1/PC1/ppc/puppet-agent-5.3.5-1.aix6.1.ppc.rpm<br>
 Puppet rpm is installed using rpm -i command line.<br>  
 After Puppet installation, path to puppet is /opt/puppetlabs/bin/puppet.<br>
 Please note that Puppet comes with its own ruby, you'll find it here after Puppet installation:<br> 
    "/opt/puppetlabs/puppet/bin/ruby -version" returns "ruby 2.4.2p198 (2017-09-14 revision 59899)" 
  
### Setup AixAutomation module
#### Clone into AIX_AUTOMATION_DIR directory 
 AixAutomation module needs to be installed into 
  /etc/puppetlabs/code/environments/production/modules, which is the install 
  directory referred as <b>INST_DIR</b> below.<br>
 You can do this by performing:<br>  
   - git clone https://github.com/aixoss/aix-puppet.git<br>   
 into INST_DIR repository.
 This creates INST_DIR/aixautomation directory, which is referred as 
  <b>AIX_AUTOMATION_DIR</b> below. <br> 
 <b>All relative paths below are related to this AIX_AUTOMATION_DIR directory.</b><br>
#### './manifests/init.pp' file  
 All AixAutomation module setups are done through the './manifests/init.pp' file 
 using DSL.<br>
#### Prerequisites 
 As a prerequisites of Puppet AixAutomation module, NIM configuration between 
  NIM server (on which this Puppet module runs), and the LPARs (on which 
  software maintenance operations are performed) needs to be properly set: 
  all LPARs which can either not be accessible through a simple 
  'ping -c1 -w5 <lpar>' command or through a simple 'c_rsh' command will be 
  excluded from the list of targets on which './manifests/init.pp' will be 
  applied. <br>
     
 List of LPARs on which rules can be applied is retrieved through NIM server by 
  getting list of standalones. As a matter of fact, only standalones really used 
  in './manifests/init.pp' are tested (see 'Facters' section below).<br>
 
### What AixAutomation module affects 
 This module requires available disk space to store updates downloaded from 
  FixCentral, and to store downloaded eFix. By default downloads are performed 
  into '/tmp', but a more appropriate file system definitely needs to be chosen 
  and then set into './manifests/init.pp' ('root' attribute of 'download' custom 
  type for AIX updates, and 'root' attribute of 'fix' custom types for eFix).  
  File system on which downloads are performed is automatically increased 
  (100 MB each time) if necessary (if system allows).<br>
 This module will perform AIX software updates of your systems, and install 
 (or remove) of eFix.  

### Beginning with AixAutomation
 Manifest './manifests/init.pp' delivered contains one suma-download  
 As far as 'update' operations are concerned:<br> 
  You can perform download operations from FixCentral (suma-downloads) and 
  create a NIM lpp_source resource with results of downloads in a first separate 
  step, then in a second step you can update LPARs using the NIM lpp_source 
  resource which was downloaded.    
 As far as 'eFix' operations are concerned:<br>
  You can perform all preparation steps without applying the eFix and see 
   the results.<br>
  You can choose to apply eFix later on.<br>
  You can remove all eFix installed if necessary.<br>
   
## Usage
### Sample of manifest: init.pp
 Some commented samples are provided in './examples/init.pp', and should be 
  used as a starting point, to customize './manifests/init.pp' which is the 
  manifest file used by the 'puppet apply' command. 

### Logs
 The "Puppet.debug('message')" method is used in Puppet framework and as well in 
  AixAutomation module and debug messages can only be seen with the use of 
  Puppet "--debug" flag on the command line.<br> 
 All other levels ("info", "warning", "error") are displayed without 
  condition.<br>   
 These Puppet log messages are displayed on console output.<br> 
 You can redirect Puppet framework outputs to one file with the use of 
  this option:  
  "--logdest=/etc/puppetlabs/code/environments/production/modules/output/logs/logfile.txt" 
  on the command line. 
 
 AixAutomation logs (and only AixAutomation log, and not Puppet log) are 
  generated into ./output/logs/PuppetAixAutomation.log.<br>
  Up to 12 rotation log files of one 1 MB are kept: 
   ./output/logs/PuppetAixAutomation.log.0 to ./output/logs/PuppetAixAutomation.log.12<br>
  These logs does not depend from Puppet --debug flag on the command line, and 
   you'll get them in any case.
 
### Installation directory 
  As said already, AixAutomation module is installed into 
   /etc/puppetlabs/code/environments/production/modules (called INST_DIR):<br> 
   /etc/puppetlabs/code/environments/production/modules/aixautomation 
   (called AIXAUTOMATION_DIR), 
   and all relative paths in this README are relative to this AIXAUTOMATION_DIR 
   directory.<br>
  The AixAutomation module generates all outputs under this directory 
   (under ./output), except downloads of updates and eFixes which are performed 
   under 'root' directories mentioned into './manifests/init.pp' file, 
   (ou have one 'root' attribute for 'download' and one 'root' directory for 
   'fix').  
 
### Command line    
  You can test './manifests/init.pp' manifest by using following command lines:<br>
        /opt/puppetlabs/bin/puppet apply \ 
          --noop --modulepath=/etc/puppetlabs/code/environments/production/modules \
          -e "include aixautomation"<br>
     or apply it without debug messages: <br>
        /opt/puppetlabs/bin/puppet apply \
          --modulepath=/etc/puppetlabs/code/environments/production/modules \
          -e "include aixautomation"<br>
     or apply it with debug messages: <br>
        /opt/puppetlabs/bin/puppet apply  --debug \ 
        --modulepath=/etc/puppetlabs/code/environments/production/modules \
          -e "include aixautomation"<br>
     or apply it with debug message and Puppet logs into a file: <br>
        /opt/puppetlabs/bin/puppet apply \ 
         --logdest=/etc/puppetlabs/code/environments/production/modules/output/logs/PuppetApply.log \
         --debug --modulepath=/etc/puppetlabs/code/environments/production/modules \
         -e "include aixautomation"<br>   
        Please note that if you use "--logdest" parameter, you won't see any 
         output on the command line as everything is redirected to log file.
            
## Reference
### Facters
 Specific AixAutomation facters collect the necessary data enabling 
  AixAutomation module to run:<br>
    - props: to have shared configuration attributes.<br>
    - applied_manifest: to read, parse and display manifests/init.pp, so that 
      we can have into log file the exact contents of manifests/init.pp used at
      runtime: this is an help for debugguing. Moreover the manifests/init.pp 
      is parsed so that the set of 'targets' really used is computed, this is 
      used when running 'standalones' facter (see below 'standalones' facter) to 
      restrict computing of this facter to the sole list of standalones used in 
      manifests/init.pp.<br> 
    - servicepacks: you'll find results on this factor into 
      ./output/facter/sp_per_tl.yml file. If this file does not exist when 
      "Puppet apply" is launched, it is computed by automatically downloading 
      Suma metadata files, all Suma metadata files are temporarily downloaded 
      under ./output/facter/suma, but are removed at the end, when new 
      ./output/facter/sp_per_tl.yml file is generated. 
      Please note that as part of this computing, metadata downloads are 
      attempted for SP of each TL until repeatedly errors occur, meaning that 
      the last SP do not exist. Therefore it is normal to have errors when we 
      reach non-existing SP, this is the way which is used to go until last 
      existing SP.  
    - standalones: to gather data on all standalones managed by the NIM server. 
      As a matter of fact list of standalones is restricted to the ones really 
      used in manifests/init.pp as explained above (refer to 'applied_manifest' 
      facter). Results can be found into ./output/facter/standalones_kept.yml 
      file, and into ./output/facter/standalones_skipped.yml file. This 
      'standalones' facter takes some time at the beginning of AixAutomation 
      module, but is necessary to know the usable standalones.<br>
    - vios: to gather data on all VIOS managed by the NIM server. 
      As a matter of fact list of VIOS is restricted to the ones really 
      used in manifests/init.pp as explained above (refer to 'applied_manifest' 
      facter). Results can be found into ./output/facter/vios_skipped.yml file
      and ./output/facter/vios_kept.yml file.<br> 
    - hmc: to gather data on all HMC managed by the NIM server. 
  
### Custom types and providers
 Four custom type and their providers constitute the AixAutomation module.<br>
 All custom types utilizations are documented into './examples/init.pp'<br>
 These four custom types constitute the vocabulary which can be used as part of 
  Puppet AixAutomation DSL into manifest file, to perform resources 
  declaration. <br> 
 
 #### Custom type: download (provider: suma)
 Used for AIX LPARs software maintenance operations.
 ##### Explanations
 The aim of this provider is to provide download services using suma 
 functionality.<br>
 Suma requests are generated so that updates are downloaded from Fix Central.<br>
 "root" attribute is used as download directory: it should be an ad-hoc file 
 system dedicated to download updates, keep this file system separated from the 
 system to prevent saturation.<br>   
 
 As a preliminary step, suma <b>metadata</b> are downloaded if ever they are not 
 locally described into './output/facter/sp_per_tl.yml' file: if this file does 
 not exist, it is generated by parsing suma <b>metadata</b> downloaded.
 As a result, this file gives for each possible technical level the list of 
 available service packs.<br> 
 As a reference, the './output/facter/sp_per_tl.yml.June_2018' delivered 
 file is the file computed from Metadata in June 2018.<br>
It is a good practice to regularly consider that the 
 './output/facter/sp_per_tl.yml' is maybe not up-to-date, and therefore let 
 'suma' provider download metadata 'in live' and compute a more recent version 
 of './output/facter/sp_per_tl.yml'. To perform this, you can rename existing 
 './output/facter/sp_per_tl.yml' to './output/facter/sp_per_tl.yml.saved' so 
 that this './output/facter/sp_per_tl.yml' is computed again. You should 
 perform this operation once in a while (every month or so).<br>
 
 As a normal step, various types of suma-downloads can be performed: 
 either "SP", or "TL", or "Latest":<br>
  - "SP" contains everything to update a system to a new Service Pack in a given
   Technical Level.<br>
  - "TL" contains everything to update a system from a Technical Level to another 
   Technical Level.<br>
  - "Latest" contains everything to update a system to the last Service Pack of 
   a given Technical Level.<br>
 As a result of suma-download a lpp_source NIM resource is created. You can choose
  either to name it (with your own way of naming) and in that case you need to 
  provide a 'lpp_source' attribute. Or you can let 'suma' provider name the 
  lpp_source, in that case naming convention uses "PAA" as a prefix to identify 
  automatically lpp_source NIM resource ("PAA" as a shortcut for 
  "<b>P</b>uppet<b>A</b>ix<b>A</b>utomation"'), then the <type> of suma-download 
  is used: "SP", "TL", "Latest", then the <from> and the <to> fields. 
  As a example, you would have: "PAA_SP_7100-03_7100-03-07-1614" indicating a 
  NIM resource to update from 7.3.0 to 7.3.7.1614 SP.<br>
 It is possible to perform only the suma 'preview' (and therefore not the suma 
  'download') by setting the 'to_step' attribute of the 'download' custom type 
  to 'preview' (you'll find an example of this into the delivered 
  './manifests/init.pp'). By default, this 'to_step' attribute is set to 
  'download', meaning that the suma-download is performed. <br> 
 One new attribute 'force' enables to force downloads of everything from scratch, 
  even if the results of downloads are already available. Set this 'force' 
  attribute to 'yes' to force downloads again. In that case, 'preview' is done 
  only if explicitly required. <br>
  By default 'force is set to 'no', meaning all previous downloads are kept and 
   reused, this can spare a lot of time. <br>  
  You'll find samples of suma-downloads into './examples/init.pp'.<br>
 ##### Attributes
 - <b>provider</b>: this attribute is not mandatory, if mentioned it needs to 
  contain name of the provider implementing the 'download' custom type, 
  therefore the value needs to be: <b>suma</b>.  
 - <b>ensure</b>: to control flow of execution, this attribute can take two 
  values, either <b>present</b> or <b>absent</b>. By default <b>present</b> 
  is assumed. 
  If set the <b>present</b>, suma command will be attempted so that what is set 
   into attributes is performed: suma-downloads according to attributes 
   values. <br> 
  If set to <b>absent</b>, result of previous <b>present</b> run is clean: 
   NIM lpp_source resource is cleaned, and results of suma-downloads are removed 
   from disks.     
 - <b>name</b>: not a mandatory attribute if you have only one 'download' 
  custom type in './manifests/init.pp'. Otherwise (multiple 'download' custom 
  types), this attribute is necessary to uniquely identify the suma-download 
  to be performed: you can have several 'download' custom types in 
  './manifests/init.pp', each of them being uniquely identified. 
 - <b>root</b>: root directory to store results of suma-download. This root 
  directory should reside on a file system separated from the one which hosts 
  the system itself, and preferably different from /tmp. This root directory 
  needs to be large enough to contain system updates, and should be an 
  exportable file system, so that NIM can create NIM lpp_source resource and 
  perform a mount from the remote LPARs.<br> 
  Note: it appears that this <b>root</b> directory needs to be either of 
  type jfs or jfs2 (some other types of file system may work too).<br>  
 - <b>type</b>: type of suma-downloads. Three possible values: <b>SP</b> to 
  suma-download a service pack, i.e. what allows you to update from a XXXX-YY 
  technical level to any service packs of this technical level. <b>TL</b> to 
  suma-download a technical level, so that you system gets updated to a new 
  technical level. <b>Latest</b> to suma-download the last service pack of a 
  given technical level. A last value is possible: <b>Meta</b> but is reserved 
  for internal use.   
 - <b>from</b>: attribute used to launch suma-download command, indicating the 
  starting level of desired updates. For example by indicating <b>7100-01</b>, 
  it means download contains everything to update from this <b>7100-01</b> 
  technical level. Or by indicating <b>7100-01-02-1150</b>, it means download 
  contains everything to update from this <b>7100-01-02-1150</b> service pack,
  but specifying a SP into the <b>from</b> is equivalent to specifying the 
  closest TL : <b>7100-01-02-1150</b> SP is equivalent to <b>7100-01</b> TL.
 - <b>to</b>: attribute used to launch suma-download command, indicating the 
  level of updates desired. For example by indicating <b>7100-03</b>, it means 
  download contains everything to update up to this <b>7100-03</b> technical 
  level, or  by indicating <b>7100-01-08-1642</b>, it means download contains 
  everything to update up to this <b>7100-01-08-1642</b> service pack.
 - <b>lpp_source</b>: name of the NIM lpp_source resource created containing 
  results of suma-downloads. If ever this lpp_source name is not provided, a 
  naming convention is used to generate this name, by using a prefix ('PAA'), 
  and by concatenating 'type', 'from', and 'to' attributes. The name of this 
  lpp_source needs to be reused when performing updates of system 
  (using 'nimpush' custom type).  
 - <b>to_step</b>: to control flow of execution up to a given step. Two 
  possible steps: <b>preview</b> and <b>download</b>. By default, 
  <b>download</b> is assumed. You can perform only <b>preview</b> suma-download, 
  by setting this attribute to <b>preview</b>, in that case download is not done.
 - <b>force</b>: to force suma-download again. Two possible values for this 
  attribute: <b>yes</b> and <b>no</b>. By default, <b>no</b> is assumed, meaning 
  that suma download won't be done again if expected results of suma-download 
  can be found under <b>root</b> directory.  
  If set to <b>yes</b>, this attribute can force a new suma-download (even if 
  this suma-download was already done, and if it can be found under <b>root</b> 
  directory) and can force the creation of a new NIM lpp_source resource 
  (even if this NIM lpp_source resource already exists). 
 
 #### Custom type: patchmngt (provider: nimpush)
 Used for AIX LPARs software maintenance operations.
 ##### Explanations
  The aim of this provider is to provide software maintenance operations on a 
  list of LPARs using NIM push mode. Everything is performed from the NIM server 
  on which this Puppet AixAutomation module runs.<br>   
  This NIM push mode can use suma-downloads performed by suma provider, as 
  preliminary step, by using into 'lpp_source' attribute the lpp_source which 
  was created by 'suma' provider.<br>
  Software maintenance operations include: install and updates.<br>
  You'll find samples of install and update into './examples/init.pp'.<br>
  You can perform operation synchronously or asynchronously depending on 'sync' 
  attribute.<br> 
  You can perform preview only depending on 'preview' attribute.<br>
  Several modes of updates exist: apply, commit, reject. See several 
   documented examples in './examples/init.pp'. 
 ##### Attributes
   - <b>provider</b>: this attribute is not mandatory, if mentioned it needs 
   to contain name of the provider implementing the 'patchmngt' custom type, 
   therefore the value needs to be: <b>nimpush</b>.  
   - <b>ensure</b>: to control flow of execution, this attribute can take two 
   values, either <b>present</b> or <b>absent</b>. By default <b>present</b> 
   is assumed. If set the <b>present</b>, NIM push operation will be attempted 
   so that what is set into attributes is performed.<br>
   If set to <b>absent</b>,  <i> missing </i>.     
   - <b>name</b>: not a mandatory attribute if you have only one 'patchmngt' 
   custom type in './manifests/init.pp'. Otherwise (multiple 'patchmngt' 
   custom types), this attribute is necessary to uniquely identify the NIM 
   push operation to be performed: you can have several 'patchmngt' custom 
   types in './manifests/init.pp', each of them being uniquely identified.<br> 
  - <b>action</b>: action to be performed. This attribute can take several 
   values: <b>install</b>, <b>update</b>, <b>reboot</b>, <b>status</b>. 
   By default, <b>status</b> is assumed. <b>install</b> action enables 
   installation (or un-installation depending on the <b>ensure</b> 
   value) of a lpp_source, <b>update</b> action enables update of a system 
   (installation of a service pack or installation of a technical level), 
   <b>reboot</b> action enables to launch reboot of LPARs. 
   <b>status</b> action displays version level and eFix information 
   related to LPARs.<br>
  - <b>mode</b>: mode of update. By default update is performed in apply mode, 
   meaning the updates are only applied, <b>mode</b> is set to <b>apply</b>. 
   It is possible to commit the updates, by setting this <b>mode</b> attribute 
   to <b>commit</b>. Or you can set <b>mode</b> to <b>reject</b>, 
   (but in that case <b>ensure</b> needs to be set to <b>absent</b>) to reject 
    all updates.      
  - <b>lpp_source</b>: name of the NIM lpp_source resource to be 
   installed/un-installed or which needs to be used to performed system update. 
   In case of update, this lpp_source is the one which was created by a previous 
   'download' custom type (results of suma-downloads). 
  - <b>targets</b>: names of the LPARs on which to perform action.
  - <b>sync</b>: if action needs to be done synchronously or asynchronously. 
   Two possible values for this attribute: <b>yes</b> and <b>no</b>. 
   By default, <b>no</b> is assumed.  
  - <b>preview</b>: if only preview must be done. Two possible values for 
   this attribute: <b>yes</b> and <b>no</b>. By default, <b>no</b> is assumed.  
    
 #### Custom type: fix (provider: flrtvc)
 Used for AIX LPARs software maintenance operations.
 ##### Explanations
 The aim of this provider is to provide appropriate eFix installations using 
  flrtvc functionality to compute list of eFix to be installable, and NIM push 
  functionality to install this list of eFix.<br> 
 "root" attribute is used as download directory: it should be an ad-hoc file 
  system dedicated to download eFix, keep this file system separated from the 
  system to prevent saturation.<br>   
 List of appropriate eFix to be installed on a system is firstly computed by 
  'flrtvc', then checked against constraints and a short list of eFix of 
  installable eFix is computed, a NIM resource is then created and then applied, 
  so that eFix are installed.<br>
 These several steps necessary to achieve this eFix installation task, are 
  performed following this order: "installFlrtvc", "runFlrtvc", "parseFlrtvc", 
  "downloadFixes", "checkFixes", "buildResource", "installResource". <br>
 Step "runFlrtvc" launches '/usr/bin/flrtvc.ksh' command which in turn downloads 
  an 'apar.csv' file into the directory used to launch the command. 
  This file remains at the end, and should cause no worry.  
 Step "buildResource" creates a NIM lpp_source resource whose name follows these 
  naming conventions: prefix is 'PAA_FLRTVC_' and suffix is name of the target, 
  for example 'PAA_FLRTVC_quimby01' for NIM resource used to perform eFix 
  installation on quimby01 LPAR. 
 Executions can be stopped after any step, and this is controlled through the 
  'to_step' attribute into './manifests/init.pp'.<br>
 Each step persists its results into a yaml file, which can be found into 
  ./output/flrtvc directory.<br> 
 All yaml files can be reused between two executions, to spare time if ever the 
  external conditions have not changed. The use of yaml files is controlled 
  through the 'force' attribute which needs to be set to 'no' if you want to use
  these yaml files and spare time. By default it is set to 'yes', meaning the 
  previously computed yaml files are not used.<br>
 eFix are sorted by 'Packaging Date' before being applied, i.e. most recent 
  first. It could occur that one particular eFix prevents another one (less 
  recent) from being installed if both eFixes touch the same file.<br>
 At the end of execution of this provider, you'll find into: <br>
  - ./output/flrtvc/[target]_StatusBeforeEfixInstall.yml: how were the [target] 
    LPAR before eFix installation.<br> 
  - ./output/flrtvc/[target]_StatusAfterEfixInstall.yml: how are the [target] 
    LPARs after eFix installation.<br>
  - ./output/flrtvc/[target]_StatusBeforeEfixRemoval.yml: how were the [target] 
    LPAR before eFix de-installation.<br> 
  - ./output/flrtvc/[target]_StatusAfterEfixRemoval.yml: how are the [target] 
    LPARs after eFix de-installation.<br>
 ##### Attributes
   - <b>provider</b>: this attribute is not mandatory, if mentioned it needs to 
   contain name of the provider implementing the 'fix' custom type, therefore 
   the value needs to be: <b>flrtvc</b>.  
   - <b>ensure</b>: to control flow of execution, this attribute can take two 
   values, either <b>present</b> or <b>absent</b>. By default <b>present</b> 
   is assumed. If set the <b>present</b>, eFix are installed by running all 
   steps. If set to <b>absent</b>, eFix are removed.     
   - <b>name</b>: not a mandatory attribute if you have only one 'fix' 
   custom type in './manifests/init.pp'. Otherwise (multiple 'fix' custom 
   types), this attribute is necessary to uniquely identify the flrtvc operation 
   to be performed: you can have several 'fix' custom types in 
   './manifests/init.pp', each of them being uniquely identified.<br> 
   - <b>to_step</b>: to control flow of execution up to a given step. 
   Possible values: <b>installFlrtvc</b>, <b>runFlrtvc</b>, <b>parseFlrtvc</b>, 
   <b>downloadFixes</b>, <b>checkFixes</b>, <b>buildResource</b>, 
   <b>installResource</b>. All these steps are performed in the given order above, 
   but you can interrupt execution after any given step, by using this 
   <b>to_step</b> attribute. <br> By default, <b>installResource</b> is assumed, 
   meaning all steps are done.<br> 
   - <b>targets</b>: names of the LPARs on which to perform flrtvc steps.
   - <b>force</b> : to force all flrtvc steps to be done again without 
   exploiting any persisted information. Two possible values for this attribute: 
   <b>yes</b> and <b>no</b>. By default, <b>yes</b> is assumed, meaning all 
   previous results of any flrtvc runs (which are persisted into yaml files) 
   are not kept, and computed again. If ever you want to spare time, 
   and reuse previous flrtvc results, or if you want or run flrtvc 
   step by step (refer to <b>to_step</b> attribute), you can keep previous 
   results by setting this attribute to <b>no</b>. 
   - <b>root</b>: root directory to store results of flrtvc download. 
   This root directory should reside on a file system separated from the one 
   which hosts the system itself. This root directory needs to be large 
   enough to contain eFix updates, and should be a exportable file system 
   (jfs, jfs2, ...), so that NIM can create NIM lpp_source resource and 
   perform a mount from the remote LPARs. By default <b>/tmp</b> is assumed. 
   - <b>type</b>: type of desired eFix. Possible values: <b>hiper</b>, 
   <b>sec</b>, <b>all</b>. 
   By default, <b>all</b> is assumed, meaning all possible eFix are installed.       

#### Custom type: vios (provider: viosmngt)
 Used for AIX VIOS software maintenance operations.
 ##### Explanations
  The aim of this provider is to provide software maintenance operations on a 
  list of VIOS using '**NIM push**' operations, and using '**c_rsh**' operations. 
  Everything is performed from the NIM server on which this Puppet AixAutomation
   module runs.<br> 
  To be able to perform VIOS updates, this NIM push mode need NIM lppsource 
  resources to exist prior from using AixAutomation. These NIM lppsource resources
  have to be manually built before using AIXAutomation Puppet module 
  (if we compare with LPAR updates, in which building NIM lppsource resources is 
  one Puppet AixAUtomation step, and can be automatically done).<br>  
  Software maintenance operations means in this case: VIOS updates.<br>
  You'll find samples of manifest declarations in Puppet AixAutomation DSL language 
  for VIOS updates into './examples/init.pp'.<br>
  The VIOS update operation can be performed in 'preview' mode only depending on 
  'options' attribute.<br> 
  Several modes of updates may exist in the future, but so far only one 
  is coded: "commit", using the 'update_options' attribute. See documented example 
  in './examples/init.pp'.<br>
  Puppet AixAutomation brings a complete logic to verify VIOS update will be safely 
  performed. Rollback operation (i.e. coming back on previous VIOS version) will be 
  always possible in case of any issue during update, as rootvg is copied before 
  performing VIOS operation.<br> 
  - For each pair of VIOS, a health check can be performed to verify that both 
   VIOS of the pair share the same view of mappings on all types of storage and 
   virtual adapters: vSCSI, vFC, SEA, VNIC, etc. 
   This health check should always be run as a preliminary step, and in case of 
   unsuccessful result, VIOS update cannot be done on any VIOS of the pair. 
   The health check is not mandatory, and could be skipped, by omitting the
    '**health**' key-word from the 'actions' attribute.   
  - Before performing a VIOS update, Puppet AixAutomation insures a copy of rootvg 
   exists or is taken, to always offer possibility to come back on previous VIOS 
   version if anything proves to be wrong during or before the end of VIOS update. 
   The copy of rootvg is taken using 'alt_disk_copy' command: the use of this 
   command results into an "altinst_rootvg" vg on a dedicated disk. 
   No VIOS update is run without an existing 'altinst_rootvg'.    
  - If ever rootvg is mirrored, as it is not possible to perform 'alt_disk_copy' 
   on a mirrored disk, the un-mirror operation of the rootvg disk is launched 
   before performing it, and this mirroring is re-established after performing it. 
   But these 'un-mirror' and 'mirror' operations won't be done without an explicit
    parameter into manifest file, so that this is an explicit choice from the user.
   - Moreover as it is not possible to update a VIOS with is a UP SSP cluster node, 
   if ever the VIOS proves to be part of a SSP cluster, a check is done the VIOS
   being part of a SSP cluster: as a matter of fact, it is necessary that SSP 
   cluster is either UP or DOWN on both VIOS of the pair. If ever both SSP 
   cluster nodes are UP before launching the VIOS updates, each SSP node is 
   stopped juste performing VIOS update operation on this very node, and 
   restarted when this VIOS update operation is finished. 
   - VIOS update logs for each VIOS can be found into ./output/vios
        Each VIOS has its own log file: updateios_output_update_<vios_name>.log
   - VIOS update journal for each VIOS can be found into ./output/vios
        Each VIOS has its own journal file: <vios_name>.yml
               
 ##### Attributes
   - <b>provider</b>: this attribute is not mandatory, if mentioned it needs 
   to contain name of the provider implementing the 'vios' custom type, 
   therefore the value needs to be: <b>viosmngt</b>.  
   - <b>ensure</b>: either <b>present</b> or <b>absent</b>. Not used to control 
   flow of execution. Both values are possible to performed VIOS update.     
   - <b>name</b>: not a mandatory attribute if you have only one 'vios' 
   custom type in './manifests/init.pp'. Otherwise (multiple 'vios' 
   custom types), this attribute is necessary to uniquely identify the VIOS  
   update operation to be performed: you can have several 'vios' custom 
   types in './manifests/init.pp', each of them being uniquely identified.<br> 
  - <b>actions</b>: actions to be performed. This attribute is a 
   multi-valuated attribute. Several values can be chosen among 
   the various values: <b>health</b>, <b>check</b>, <b>save</b>, <b>mirror</b>,
    <b>autocommit</b>, <b>update</b>. By default, no value is assumed. <br>
   <b>health</b> action enables VIOS health check prior from making update. 
   If this health check is negative, VIOS update operation won't be 
   pursued. This action should be always run, but is independent and can 
   be skipped by omitting the 'health' key-word from 'actions' attribute.<br>
   <b>check</b> action enables mirror and SSP cluster checks.<br> 
   <b>save</b> action enables the save copy of the rootvg to be taken prior 
   from performing update. As already said, an 'altinst_rootvg' needs to 
   exist on a given VIOS before VIOS update can be launched on this 
   specific VIOS. Several ways of providing an 'altinst_rootvg' or insuring 
   that this 'altinst_rootvg' exists are brought by this 'save' action. 
   Refer to below <b>vios_altinst_rootvg</b> and <b>altinst_rootvg_force</b> 
   attributes.<br>   
   <b>autocommit</b> action enables autocommit of 'applied only' updates 
   to be done if necessary before performing VIOS update. VIOS update 
   is not possible if ever all previous installations are not committed.<br>
   <b>mirror</b> action is necessary to un-mirror rootvg before 
   performing the save operation (taking an altinst_rootvg), and if 
   un-mirror is done, mirror will be retablished afterwards. 
   No 'un-mirror' and 'mirror' operations will be done  
   without this explicit key-word into 'actions' attribute.<br> 
   <b>update</b> action to perform VIOS update operation itself. If ever this action 
   is not set, Puppet AixAutomation performs only all other preparation steps which
   are listed into 'actions' attribute.  
  - <b>vios_pairs</b>: pairs of VIOS on which to perform action.
  - <b>update_options</b>: only possible value is <b>commit</b>. Potential future 
   values are <b>install</b>, <b>commit</b>, <b>reject</b>, <b>cleanup</b>, 
   <b>remove</b>.<br>       
  - <b>options</b>: possible values are <b>accept_licenses</b> and <b>preview</b>.
   <b>options=accept_licenses</b> is necessary when <b>actions</b> contains <b>update</b> 
   otherwise update fails on 'accept_licences' condition. Explicit agreement is needed to 
   accept licences. <br> 
   <b>options=preview</b> can be set to perform VIOS update in preview mode only. Without 
   <b>options=preview</b>, VIOS update is really performed.<br> 
  - <b>vios_altinst_rootvg</b>: this attribute enables to designate a disk to be used 
  to host 'altinst_rootvg'. A disk can be designated per VIOS following this given syntax : 
  <b>vios1=hdisk1, vios2=hdisk2</b> etc. The given disk will be used as a first choice, 
  if this disk fits the necessary conditions to host a copy of the rootvg. If 
  this disk cannot be used, the best disk possible will be chosen : a free disk large 
  enough to host rootvg, but the smallest disk possible (between all large enough) will 
  be taken to spare resources.<br>    
  - <b>altinst_rootvg_force</b>: possible values are 
  <b>no</b>, <b>yes</b>, <b>reuse</b>. <br>
  <b>altinst_rootvg_force=no</b> means that if ever it already exists an 'altinst_rootvg', 
  this one won't be overriden. As the presence of an existing 
  'altinst_rootvg' will prevent a new 'altinst_rootvg' from 
  being taken, and will prevent the overall process of VIOS update from continuing. 
  If no altinst_rootvg exists, a new one is created just before VIOS update.<br>
  <b>altinst_rootvg_force=yes</b> means that if ever it already exists an altinst_rootvg, 
  this one is going to be cleaned and removed, allowing a new one to be taken just before 
  VIOS update.<br> If no altinst_rootvg already exists, one altinst_rootvg will be taken 
  just before VIOS update. <br>
  <b>altinst_rootvg_force=reuse</b> means that if ever it already exists an altinst_rootvg, 
  this one is going to be kept and used, therefore no 'fresh' altinst_rootvg is taken 
  as we consider the existing one as valuable. If no altinst_rootvg exists, one 
  altinst_rootvg will be taken just before VIOS update. <br>
  - <b>vios_lpp_sources</b>: this attribute enables to designate the NIM lppsource 
  resource to be used to perform VIOS update operation. A NIM lppsource resource can be 
  designated per vios following this given syntax : 
  <b>vios1=lpp_source1, vios2=lpp_source2</b> etc. 
  These given lppsources need to exist before launching Puppet AIXAutomation. <br>
         
## Limitations
 Refer to TODO.md<br>

## Development
 Refer to TODO.md<br>

## Release Notes 
 ### Debugguing tips
 #### Shell environments 
 Shell environments may cause errors with underlying (shell) system commands.  
 So, it may require an unset of the terminal environment before use. 
  (For example, if ever you have in your environment this variable set: 'ENV=/.kshrc', 
   this can lead to abnormal behaviour, not well explained. In that case, perform 
   'unset ENV' before retrying.)

 #### Notes on log outputs
 Error log outputs are displayed in red. Some of these red output cause no incidence, and
 Puppet AixAutomation module can live with without problem. Some of them are listed below. 
  
 ##### Output of /usr/sbin/emgr -dXv3
 The following output is frequently displayed when "/usr/sbin/emgr -dXv3 -e ABCD.epkg.Z"  
  command is run, but this does not prevent the parsing of this command output to be done.<br>
  
  Error:     emgr: 0645-007 ATTENTION: /usr/bin/lslpp returned an unexpected result.<br>
  Error:     emgr: 0645-044 Error processing installp fileset data.<br>
  Error:     emgr: 0645-060 Unable to determine owning fileset 
                for /opt/pconsole/bin/pconsole_config.<br>
  Error:     emgr: 0645-097 Error processing inventory data for file number 1.<br>
  Error:     emgr: 0645-140 ATTENTION: emgr has issued 1 attention notice(s).<br>
  Error:     Such notices may not indicate an immediate failure, but may require<br>
  Error:     further attention. Please see the output above or the log for more details.<br>
  
 ##### Output of /usr/sbin/suma -x -a Action=Preview
 The following output is always displayed when "/usr/sbin/suma -x -a Action=Preview" 
  command is run, but you can pay no attention to this output.<br>   
  Error: ****************************************<br>
  Error: Performing preview download.<br>
  Error: ****************************************<br>
    
 ### Contributors
 Refer to TODO.md file
 