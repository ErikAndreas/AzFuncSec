param funcAppName string
param appInsightsKey string
param appInsightsConnectionString string
/*@secure()
param storageAccountConnectionString string*/
param stConnStrKvKey string
param kvName string
param connStrServiceUri string
param dbConnStr string
param signalRServiceUri string

resource functionAppAppsettings 'Microsoft.Web/sites/config@2020-12-01' = {
  name: '${funcAppName}/appsettings'
  properties: {
    APPINSIGHTS_INSTRUMENTATIONKEY: appInsightsKey // https://stackoverflow.com/questions/60691568/why-do-i-need-both-appinsights-instrumentationkey-and-applicationinsights-connec
    APPLICATIONINSIGHTS_CONNECTION_STRING: appInsightsConnectionString
    //AzureWebJobsStorage: storageAccountConnectionString
    AzureWebJobsStorage: '@Microsoft.KeyVault(VaultName=${kvName};SecretName=${stConnStrKvKey})'
    FUNCTIONS_EXTENSION_VERSION: '~4'
    FUNCTIONS_WORKER_RUNTIME: 'dotnet'
    //WEBSITE_CONTENTAZUREFILECONNECTIONSTRING: storageAccountConnectionString
    WEBSITE_CONTENTAZUREFILECONNECTIONSTRING: '@Microsoft.KeyVault(VaultName=${kvName};SecretName=${stConnStrKvKey})'
    WEBSITE_CONTENTSHARE: toLower(funcAppName)
    StorageConnStr__serviceUri: connStrServiceUri
    DbConnStr: dbConnStr
    AzureSignalRConnectionString__serviceUri: signalRServiceUri
  }
}

resource functionAppWebSettings 'Microsoft.Web/sites/config@2020-12-01' = {
  name: '${funcAppName}/web'
  properties: {
    http20Enabled: true
    minTlsVersion: '1.2'
    ftpsState: 'FtpsOnly'
  }
}
