param location string = resourceGroup().location
param appName string = 'mitestiac'
param env string = 'd'
param kvName string = ''

/* 
resources:
https://docs.microsoft.com/en-us/azure/azure-resource-manager/bicep/
https://medium.com/cheranga/azure-bicep-and-azure-devops-to-deploy-a-function-app-a707c13b2bff
https://bicepdemo.z22.web.core.windows.net/

naming:
https://docs.microsoft.com/en-us/azure/cloud-adoption-framework/ready/azure-best-practices/resource-naming
https://docs.microsoft.com/en-us/azure/cloud-adoption-framework/ready/azure-best-practices/resource-abbreviations
resource group: rg<xx>-<app>-<env>

MS Standard:
<type>-<app>-<env>
func- (func app)
sql- (server)
sqldb- (db instance)
st (storage, a-z0-9 only, len 3-24)
stfunc (function app storage)
evhns- (event hub namespace)
evh- (event hub)
sigr- (signalr)
plan- (app service plan (serverfarm))
appi- (application insights)
log- (log analytics workspace)

sample invocation: > az deployment group create --resource-group rg01-mitestiac-d --template-file .\main.bicep --parameters kvName=kv01-mitestiac-d
*/

resource kv 'Microsoft.KeyVault/vaults@2021-11-01-preview' existing = {
  name: kvName
}

module appInsightsModule 'appInsights.bicep' = {
  name: 'appi01-${appName}-${env}'
  params:{
    name: 'appi01-${appName}-${env}'
    rgLocation: location
  }
}

module fnAppStorageAccountModule 'storageAccount.bicep' = {
  name: 'stfunc01${appName}${env}'
  params: {
    saName: toLower('stfunc01${appName}${env}')
    location: location
    sku: 'Standard_LRS'
    softDelete: false
    keysToVault: true
    kvName: kvName
  }
}

module appStorageStorageAccountModule 'storageAccount.bicep' = {
  name: 'st01${appName}${env}'
  params: {
    saName: toLower('st01${appName}${env}')
    location: location
    sku: 'Standard_LRS'
    softDelete: true
    kvName: kvName
    allowSharedKeyAccess: false
  }
}

module appServiceModule 'appService.bicep' = {
  name:'plan01-${appName}-${env}'
  params:{
    hostingPlanName: 'plan-${appName}-${env}-${substring(uniqueString(resourceGroup().id),0,5)}' // ${uniqueString(resourceGroup().id) deterministic hash...
    location: location
  }
}

module fnAppModule 'funcApp.bicep' = {
  name: 'func01-${appName}-${env}'
  params: {
    planId: appServiceModule.outputs.planId
    location: location
    functionAppName:'func01-${appName}-${env}'
  }
  dependsOn:[
    appServiceModule
  ]
}

module addKvAccessPolicy 'addKvAccessPolicy.bicep' = if (!empty(kvName)) {
  name: kvName
  params: {
    kvName: kvName
    miOid: fnAppModule.outputs.fnAppPrincipalId
  }
  dependsOn: [
    fnAppModule
  ]
}

module sqlModule 'sqlServer.bicep' = {
  name:'db01-${appName}-${env}'
  params:{
    sqlserverName: 'sql01-${appName}-${env}'
    databaseName: 'sqldb01-${appName}-${env}'
    location: location
  }
}

module signalRModule 'signalR.bicep' = {
  name:'sigr01-${appName}-${env}'
  params:{
    name: 'sigr01-${appName}-${env}'
    location: location
    env: env
  }
}

module fnAppConfigModule 'funcAppSettings.bicep' = {
  name: 'func-conf-${appName}-${env}'
  params: {
    storageAccountConnectionString: kv.getSecret('${fnAppStorageAccountModule.name}ConnStr')
    appInsightsKey: appInsightsModule.outputs.appInsightsKey
    appInsightsConnectionString: appInsightsModule.outputs.appInsightsConnectionString
    funcAppName: fnAppModule.name
    connStrServiceUri: 'https://${appStorageStorageAccountModule.name}.blob.core.windows.net/'
    dbName: sqlModule.outputs.dbName
    dbServer: sqlModule.outputs.serverName
    signalRServiceUri: 'https://${signalRModule.name}.service.signalr.net'
  }
  dependsOn:[
    fnAppModule
    appInsightsModule
    fnAppStorageAccountModule
  ]
}
