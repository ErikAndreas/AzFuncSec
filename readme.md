# Azure functions and Security
"Your account control strategy should rely on identity systems for controlling access rather than relying on network controls or direct use of cryptographic keys" 

\- Microsoft Well Architected framework Security pillar 

## About
This project explores options for using Managed Identity and Azure Active Directory as the main mean of authentication and authorization rather than connection strings or access keys for various Azure Resources from an Azure Function application. Setup should work locally. 

The [DefaultAzureCredential](https://docs.microsoft.com/en-us/dotnet/api/overview/azure/identity-readme#defaultazurecredential) and [Managed Indentity](https://docs.microsoft.com/en-us/azure/app-service/overview-managed-identity) is central in all of these setups, read up on it!

## Roadmap / TODO
- Event/IoT hubs

## IaC with Bicep
* intall bicep extension to VS code (optional)
* make sure az cli is intalled
```
>az bicep install
>az login 
```
* run init, see source comments for details
* run main, see source comments for details, note: will create sqlserver with a login
* review aad ps for naming
* run aad.ps1, will: 
  * setup aad group w logged in user + func app managed identity
  * setup roles for storage access 
  * create sqlserver admin group, set sqlserver aad admin and enable ad only auth (latter could be done from bicep but would require admin group sid)
* enpoint /api/storage should work now
* execute script in db, either via az portal Query editor or by logging into db via e.g. SSMS (auth AAD - Universal with MFA)
```sql
// change to your func app name!
CREATE USER [func-app-name] FROM EXTERNAL PROVIDER;
ALTER ROLE db_datareader ADD MEMBER [func-app-name];
ALTER ROLE db_datawriter ADD MEMBER [func-app-name];
```
* NOTE!!! main script can't be run again unless sql aad auth only is disabled, you need to disable it (see rmsqlaad.ps1) to re-run main script
* seed table 'test' (See Data class) to run /api/sql endpoint
* run aadappauth to create aad client app for aad protection on endpoint /api/secendpoint (which is called from /api/index via xhr - browse to /api/index to login to your aad)


## Functions

### Key Vault
Most fundamental to keep sensitive data away even though app settings/env vars are encrypted at rest.

1. create key vault 
2. create secret(s)
3. add access policy for secret 'get' to func app with already set system assigned identity

local setting/usage (local.settings.json)
```json
"SecretVar": "local (not so) secret"
```
app setting in az
```json
"SecretVar": "@Microsoft.KeyVault(VaultName=<key vault name>;SecretName=<secret name>)" 
```
Also see source for getting secrets directly from vault in code (not 'via' setting/env var)

#### Links
- https://docs.microsoft.com/en-us/azure/app-service/app-service-key-vault-references

### Azure SQLServer
1. create Azure SQLServer and database, only allow AAD auth
2. set AAD admin, preferably a group account and add whoever needs admin access
3. set firewall rules
4. test connection with e.g. SSMS using AAD - universal with mfa login
5. create a table ('test' is used here)
6. create function app, http triggered VS 2022, copy code from here
7. create Azure function app, set system assigned identity
8. add func app managed identity (function app name) as db user + roles

Sample local.settings.json
```json
{
  "IsEncrypted": false,
  "Values": {
    "AzureWebJobsStorage": "UseDevelopmentStorage=true",
    "FUNCTIONS_WORKER_RUNTIME": "dotnet",
    "DbConnStr": "Server=localhost;Database=test;Trusted_Connection=True;TrustServerCertificate=true;", // as of v4 of ms.data.sqlclient all conns are encrypted
    "_DbConnStr": "Server=<dbservername>.database.windows.net; Authentication=Active Directory Default; Database=test;"
  }
}
```

This setup allows for local func app querying azure db (using 2nd conn str) as well as local db (using 1st conn str)
#### Sources, links and additional reading
- https://docs.microsoft.com/en-us/azure/architecture/framework/security/security-principles
- https://docs.microsoft.com/en-us/azure/app-service/tutorial-connect-msi-sql-database?tabs=windowsclient%2Cef%2Cdotnet
- https://devblogs.microsoft.com/azure-sdk/azure-identity-with-sql-graph-ef/
- https://www.techwatching.dev/posts/sqlclient-active-directory-authent
- https://weblog.west-wind.com/posts/2021/Dec/07/Connection-Failures-with-MicrosoftDataSqlClient-4-and-later
- https://blog.novanet.no/passwordless-connectionstring-to-azure-sql-database-using-managed-identity/

### Storage
note: blob trigger not [reliant](https://docs.microsoft.com/en-us/azure/azure-functions/functions-bindings-storage-blob-trigger?tabs=csharp#polling)

1. create new az storage account, note blob service url (https://\<storage account name>.blob.core.windows.net)
2. assuming already existing az func app with set (managed) identity
create new aad security group, add your user(s) and the func app as members
3. disable storage account key access
4. default AAD auth in az portal
5. add iam role assignments to storage account, storage blob data owner and storage queue data contributor  https://docs.microsoft.com/en-us/azure/azure-functions/functions-bindings-storage-blob-trigger?tabs=csharp#grant-permission-to-the-identity
6. az func app setting key: StorageConnStr__serviceUri
7. local func app setting key for az storage auth'ed by AAD using account added to group StorageConnStr:serviceUri
8. local func app setting key using emulated local storage "StorageConnStr": "UseDevelopmentStorage=true"

note: connection (here StorageConnStr) can not coexist as setting with __suffix

sample settings, note: none of this can coexist as setting - must be one of
```json
"StorageConnStr": "UseDevelopmentStorage=true", // all local
"StorageConnStr:serviceUri": "https://<storage account name>.blob.core.windows.net/", // local func remote az storage
"StorageConnStr__serviceUri": "https://<storagae account name>.blob.core.windows.net/" // az runtime, az storage
```
#### Sources, links and additional reading
- https://docs.microsoft.com/en-us/azure/azure-functions/functions-reference?tabs=queue#local-development-with-identity-based-connections
- https://docs.microsoft.com/en-us/azure/azure-functions/functions-bindings-storage-blob-trigger?tabs=csharp#identity-based-connections
- https://docs.microsoft.com/en-us/azure/azure-functions/functions-bindings-storage-blob#storage-extension-5x-and-higher

### SignalR
1. Create serverless SignalR service, disable Keys -> Access Key
2. Add role assignment "SignalR Service Owner" (not "SignalR App Server") on SignalR service (IAM) to func app managed identity (and your user for local dev access) or preferably a group incl app id and devs (role assignments take time to be in effect)
3. For local dev add 
```json
    "AzureSignalRConnectionString:serviceUri": "https://<servicename>.service.signalr.net"
```
4. az func app setting key <CONNECTION_NAME_PREFIX>__serviceUri, same value as local

#### Sources
- https://docs.microsoft.com/en-us/azure/azure-signalr/signalr-howto-authorize-managed-identity
- https://devblogs.microsoft.com/azure-sdk/introducing-azure-identity-support-in-the-azure-functions-signalr-extension-beta/
- https://docs.microsoft.com/en-us/azure/templates/microsoft.signalrservice/signalr?tabs=bicep