Updated 7/31 - The following variables are now provided from the VMDB

- Hyper-V host credentials
- Azure provider credentials

- The following are user supplied via dynamic dialogs:

- Destination storage account
- Azure resource group

Contents of repo:

1. JMR(directory) - the unzipped automate domain contents
2. ansible-playbook(dir) - directory containing the ansible playbook to prep the VM for migration
3. datastore*.zip - Dump of the automate code from the CFME UI, for import via UI into another environment
4. dialog_export_20160722_110355.yml - Export of service dialogs for getting resource groups, storage accounts, or both via automate



Next steps:  

The last hard coded set of values are the VM's network configuration.  I to add code to create a public ip & put a dialoge in front of it to set hostname and such.  

Also, currently the storage account & resource group dialogs are independent of each other - I need to set the SA dialog to be dependent on the resource group so that users can't select a storage account that's not in the selected resource group
