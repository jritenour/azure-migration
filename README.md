As of 7/21, the automate code now gets Azure credentials from the Azure provider defined in CFME. Instances where multiple Azure providers are defined will be addressed at a later date.

Storage accounts are now derived from "list_all", rather than "list", which also requires a Resource group  be defined.

Contents of repo:

1. JMR(directory) - the unzipped automate domain contents
2. datastore_2016_07_21.zip - the zipped automate domain contents, ready for gui impomrt
3. ansible-playbook(dir) - directory containing the ansible playbook to prep the VM for migration
4. dialog_export_20160721_103542.yml - Sample dialog to get storage accounts


Next steps:  

I've got a few more values that are hard coded that I want to make dynamic.  Once that's done, I'll be ready to put this on manageiq depot, I believe.  
