# aixautomation

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
 This aixautomation module enables automation of install and update operations on a list 
  of LPAR from a NIM server on which Puppet runs.
 Necessary updates are automatically downloaded from FixCentral using 'suma' functionalities, 
  and are locally kept and shared between LPARs if possible.
 Updates can be automatically applied on a list of LPAR, through 'nim push' operation, therefore 
  everything runs from the NIM server, and nothing needs to be installed on LPAR themselves.
 Necessary efix are retrieved using 'flrtvc', downloaded, kept locally and shared between LPAR, 
  then applied on a list of LPAR.
 This module has been developed against Puppet 5.3.3.  

## Setup
 All setup are done through the manifests/init.pp file.  

### What aixautomation affects 
 This module requires some disk space to be able to download updates from FixCentral, and to download efix.
 This modules will update LPAR, and install efix.

### Setup Requirements 

 This module requires that the LPAR which are targeted to be updated are managed by the same NIM server 
  than the one on which Puppet runs.
 
### Beginning with aixautomation

 As a starter, you can only perform a status, which will display the 'oslevel -s' result and 'lslpp -l' 
  results of command on the list of LPAR you want to update. 
  
 As far as 'update' operation are concerned : 
  You can perform download operations from FixCentral separately and see results
  You can update in preview mode only, just to see the results, and decide to apply later on.
  
 As far as 'efix' operations are concerned :
  You can perform all preparation steps without applying the efix ans see the results
  You can choose to apply efix later on 
  You can remove all efix installed if necessary 
 
## Usage

 A large number of commented samples are provided in examples/init.pp
 Puppet AixAutomation Logs are generated into /tmp/PuppetAixAutomation.log. Up to 12 rotation log files of 
  one 1MG are kept.
 
  Module is installed into /etc/puppet/modules : /etc/puppet/modules/aixautomation
  You can customize /etc/puppet/modules/aixautomation/manifests/init.pp and 
     then apply it using following command lines :
        puppet apply --modulepath=/etc/puppet/modules -e "include aixautomation"
     or : 
        puppet apply --logdest /tmp/PuppetApply.log --debug --modulepath=/etc/puppet/modules -e "include aixautomation"   
 

## Reference

 Specific facters collect the necessary data enabling aixautomation module to run
    debug_level 
    servicepacks
    standalones
 
 Three custom type and their providers constitute the aixautomation module
     custom type  : provider
 =============================
 1   download     : suma
 2   fix          : flrtvc
 3   patchmngt    : nimpush 
   
 All custom-types are documented into examples/aixautomation.pp
   
## Limitations

 Missing 

## Development

 To be done 

## Release Notes/Contributors/Etc. **Optional**

 Last changes
