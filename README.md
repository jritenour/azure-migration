Updated 7/31 - The following variables are now provided from the VMDB

- Hyper-V host credentials
- Azure provider credentials

- The following are user supplied via dynamic dialogs:

- Azure resource group
- Azure storage account
- Azure network
- Azure subnet1

- Users can now enter the name for their public IP & network interface resources.

Contents of repo:

1. JMR(directory) - the unzipped automate domain contents
2. ansible-playbook(dir) - directory containing the ansible playbook to prep the VM for migration
3. datastore*.zip - Dump of the automate code from the CFME UI, for import via UI into another environment
4. dialog_*.yml - Export of service dialogs for getting resource groups, storage accounts, or both via automate



Next steps:  

Add dialog box for setting a password to the instance, or having one randomy generated & passed to the user somehow
