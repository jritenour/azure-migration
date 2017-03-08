## Update 3/8/17

As I started setting this up from scratch in a new environment, I realized I forgot to document the steps required for setting up the host where the powershell cmdlets will be installed & ran.  That has been added.  It also served as an opportunity to validate everything runs in CF 4.2, which was released in January.

## Update 2/16

In order to fix an issue occuring with CloudForms 4.2, I have updated the ruby scripts under azure-migration/JMR/Azure/Orchestration.class/ to pass long the subscription_id value gathered from the Azure provider.  I have not tested further in CF 4.2, so I'm not sure if everything works beyond basic authentication.

##Update 12/13

Please see license/usage information at the bottom of this page.  

##Update - 11/10
In preparation for some changes coming to automation domains in CloudForms 4.2, I have decided to break out the Ansible unconfig playbook to it's own [github repo](https://github.com/jritenour/sysunconfig).  I may possibly add it to Ansible Galaxy at some point in the near future as well.  

I don't expect to make any more significant changes or work on the automation method until after CloudForms 4.2 is released.  I haven't had a chance to play with the betas much at this point, but as I alluded to, there are changes to automation, and I'd rather wait until it's GA and possibly make some changes to the code structure, adding state machines for various stages of migration.  

##Update - 10/12

VMware is now officially supported.  I've been working on this for a while now, and I've gone back and forth with several different methods to convert VMDKs to VHDs for Azure.  I ended up being stuck between the hard choices of either modifying CFME appliances (needing qemu-img at a minimum, and LOT of extra disk space at a custom mount point), or having the actual conversion process run on an external host that can be sspecific via dialog/schema.  I ended up going with the external host - I'd rather not require the CFME appliances be modified in any way, and doesn't scale to large environments.  Currently, the conversion process requires a Windows host, and I'm taking advantage of Microsoft's VM conversion toolkit and powershell cmdlets.  Qemu-img has given me inconsistent results with converting from vmdk to VHD that actually boots on Azure.  I'll revist this at a later time, and see if I can at least make it possible to specify a linux host & utilize qemu-img, but for now, I'm going the path of least resistance.  

Note that the conversion host must have the [Microsoft Virtual Machine Converter](https://technet.microsoft.com/en-us/library/dn873998(v=ws.11).aspx) and the [Azure ARM PowerShell modules](https://azure.microsoft.com/en-us/documentation/articles/powershell-install-configure/) installed, and a significant amount of disk space. At least double the size of any virtual disks you intend to convert.  

My next step is to try to tackle RHEV as a source provider.  I don't have an ETA for that at this time.  

##Update - 9/02

I've broken the Ansible playbook into roles (generic Linux, Red Hat family, Debian family, and Windows) to make things a bit more organized.  Roles execute based on gathered facts.

I've also begun testing & have successfully migrated a VM from VMware to Azure using hard-coded values in Ruby.  Now I just need to incorporate into CFME and figure out how I want to organize it in relation to the Hyper-V/SCVMM specific code. 

##Update -8/20

* I have broken out some RHEL/Centos specific commands in the ansible playbook and added ubuntu/debian specific commands.  I have verified the playbook works against ubuntu hosts as expected, but not within the context of the migration method.  I will test this later this weekend or Monday.
* Also, the playbook now configures grub for the necessary options to do serial redirection on Azure.


##Update - 8/12 

- Basic support for Windows VMs added.
- Dialog now has option to set password for VM, choose OS type type (Windows or Linux), and select instance size


##Updated 7/31 

* The following variables are now provided from the VMDB:

  * Hyper-V host credentials
  * Azure provider credentials

* The following are user supplied via dynamic dialogs:
  * Azure resource group
  * Azure storage account 
  * Azure network
  * Azure subnet

*  Users can now enter the name for their public IP & network interface resources.

## Contents of repo:

1. JMR(directory) - the unzipped automate domain contents
2. ansible-playbook(dir) - directory containing the ansible playbook to prep the VM for migration
3. datastore*.zip - Dump of the automate code from the CFME UI, for import via UI into another environment
4. dialog_*.yml - Export of service dialogs for getting resource groups, storage accounts, or both via automate


## Next steps:  

* Add support for other Linux distros to the Ansible playbook - I think at a minimum, I'll need to account for different installation methods with regard to the Azure agent (ie apt vs yum)
* Begin working with other on-prem virt providers.  I'm probably going to prioritize RHEV over OpenStack or VMWare as I already have it setup in my lab.
  

## Instructions:

### Conversion/Hyper-V host setup
*NOTE:* Certain values are hard-coded still, and I'll alleviate that in an update in the very near future.  In the meantime, if you wish to change any of the paths from what I have specified, edit the migration method under JMR/Azure/Orchestration

1. Install the [Azure ARM PowerShell modules](https://azure.microsoft.com/en-us/documentation/articles/powershell-install-configure/).
2. If you will using VMware as your on-prem source, install the [Microsoft Virtual Machine Converter](https://technet.microsoft.com/en-us/library/dn873998(v=ws.11).aspx).
3. Run "Login-AzureRmAccount" from a powershell window.  Enter your credentials to authenticate to Azure RM.
4. Run "Save-AzureRMProfile -Path C:\creds\azure.txt".  This will save your token/cookie so CF can use it later.
5. Create a directory called "images" under C:\.
6. 

### CloudForms Automate setup:
1. In CloudForms, navigate to Automate -> Import/Export.
2. Export the datastore so that you have a backup.
3. Click Browse to navigate to the location of the file (datastore*.zip) to import.
4. Click Upload.
5. Navigiate to Automate -> Explorer
6. Select the domain (named JMR by default)
7. Click configuration, then edit selected domain
8. Click the enabled checkbox
9. Click save
10. Navigate to Automate -> Customization
11. In the Import/Export accordion, click Service Dialog Import/Export.
12. In the Import area, click Browse to select the dialog_export*.yaml file.
13. Click Upload.
14. Follow the steps to create a custom button at https://access.redhat.com/documentation/en/red-hat-cloudforms/4.0/single/scripting-actions-in-cloudforms/#invoking_automate_using_a_custom_button with these inputs
15. Select "Request" from the "System/Process" dropdown
16. Enter "create" as the message (without quotes)
17. Enter "Call_Instance" as the request (without quotes)
18. Use the Folloing Attribute/value pairs:
* Namespace = JMR/Azure
* Class = Orchestration
* Instance = migration
19.  If you will be converting VMware VMs, go back to Automate -> Explorer, and edit the migration instance under JMR/Azure/Orchestration.  Input your conversion host's (the one with the powershell cmdlets & MS VM converter installed) hostname or IP address, the username & password, and the path to store converted disk images (c:\creds is that is hard-coded currently). 


### Ansible Tower Setup
1. Copy the ansible-playbook/unconfig.yaml file to /var/lib/awx/projects/*nameofproject*.
2. Follow the steps at http://docs.ansible.com/ansible-tower/latest/html/userguide/inventories.html#red-hat-cloudforms to setup Ansible dynamic CloudForms inventory for Tower 3.x.  Use https://allthingsopen.com/2015/11/17/ansible-tower-dynamic-inventory-from-cloudforms/ for 2.x
3. Configure Ansible Tower provider in CloudForms - http://cloudformsblog.redhat.com/2016/07/29/ansible-tower-provider-in-cloudforms/
4. Create a new job template using the provided playbook, and your CloudForms inventory http://docs.ansible.com/ansible-tower/latest/html/quickstart/create_job.html NOTE: the automate job assumes a template name of seal_vm.  If you call your job template something else, you will need to edit the migration method under JMR/Azure/Orchestration


At this point, you should now a have custom button show up on your VMs in your cloudforms inventory. Clicking that will invoke the migration dialog, which will make calls to the Azure provider you have defined in CloudForms to gather resource groups, and enable selection of storage accounts, networks and subnets.  At this point, these resources must be created ahead of time, I have not allowed for dynamic creation of resources (but that is on my short-term roadmap)

For an overview of how it works from this point, see my video at https://www.youtube.com/watch?v=6_YA8uiA_0g

# Copyright/License Info

Copyright 2017 Jason Ritenour

This project is licensed under the terms of the MIT license.

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
