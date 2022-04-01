# Get started/setup
* intall bicep extension to VS code (optional)
* make sure az cli is intalled
```
>az bicep install
>az login 
```

# Workflow
1. find out your AAD objectId and use as param to init.bicep
2. run init.bicep, will create resource group and key vault
3. set sql admin password secret in key vault, key 'sqlServerAdminPwd'
4. run main.bicep, most resources created
5. setup diagnostics logging on storage account via azure portal (see Issues)
6. run script to create db and app db user (do not use adm for app)
7. run script to create tables and any seed data
8. create AAD applications via portal
9. onboard installation(s)
10. add sql connection string for app db user in func app settings
11. run enableStaticwebsite (or its contents) 

# Deploy
* make sure you're in the right subscription (change: >az account set --subscription "{subID|name}", verify: >az account show)
* evalaute changes (what-if): >az deployment group what-if --resource-group {rg-appname-env} --template-file main.bicep

# Assumptions
* az cli installed
* Resource group is already existing/created (e.g. via az cli)
* Resource sizing differs per environment
* supportsHttpsTrafficOnly defaults to true for storage accounts
* Storage account primary endpoint web exists even though static website is not enabled

# Environments and resource sizing
* 'prod' is assumed to indicate the production environment and has different specs than other environments
* Other (than 'prod') environments may be named arbitrary but suggested is e.g 'int' (integration) and 'prep' (pre-production)
* Environment name is expected to match resource group suffix, i.e. rg-{appname}-int and env 'int'

# Issues
* Log Analytics resources can be created but setting diagnostics logging on storage accounts does not yet seem to work (see links in storageAccount.bicep)
* Enabling static website on storage account not yet supported by bicep. Now solved with inlined powershell.
* Can't create Key vault without purge protection (meaning vault not possible to delete until retionperiod days)

# Debug
Errors will refer the created ARM template (json), >az bicep build --file .\main.bicep will output a json in same directory

# Cleanup
To remove all resources in a resource group: >az group delete --name {resource group}

# TODO
* app settings + env specs (devops pipeline integration)
* deployment slots
* AAD apps