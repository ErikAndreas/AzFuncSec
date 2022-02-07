# Azure functions and Security
"Your account control strategy should rely on identity systems for controlling access rather than relying on network controls or direct use of cryptographic keys" 

\- Microsoft Well Architected framework Security pillar 

## About
This project explores options for using Azure Active Directory as the main mean of authentication and authorization for various Azure Resources from an Azure Function application.

## Functions
### Azure SQLServer
1. Create Azure SQLServer and database, only allow AAD auth
2. Set AAD admin, preferably a group account and add whoever needs admin access
3. Set firewall rules
4. Test connection with e.g. SSMS using AAD - universal with mfa login
5. Create a table ('test' is used here)
6. Create function app, http triggered VS 2022, copy code from here
7. Create Azure function app, set system assigned identity
8. Add func app managed identity (function app name) as db user + roles

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
