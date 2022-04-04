// https://docs.microsoft.com/en-us/azure/azure-resource-manager/bicep/bicep-functions-resource#example
// transparent data encryption seems to be enabled by default
param location string = resourceGroup().location
param sqlserverName string
param databaseName string


resource sqlserver 'Microsoft.Sql/servers@2021-02-01-preview' = {
  name: sqlserverName
  location: location
  properties: {
    administratorLogin: 'sqlAdministratorLogin' // will be overridden by aad
    administratorLoginPassword: 'sqlAdmPwd01!$' // will be overridden by aad
    version: '12.0'
    minimalTlsVersion: '1.2'
  }
}

// https://docs.microsoft.com/en-us/azure/templates/microsoft.sql/2021-02-01-preview/servers/databases?tabs=bicep
resource sqlserverName_databaseName 'Microsoft.Sql/servers/databases@2021-02-01-preview' = {
  name: '${sqlserver.name}/${databaseName}'
  location: location
  sku: {
    name: 'Basic' // change for prod
    capacity: 5 // DTU's
  }
  properties: {
    collation: 'SQL_Latin1_General_CP1_CI_AS'
    maxSizeBytes: 1073741824 // TODO change and diff per env
  }
}

resource fw_AzureServices 'Microsoft.Sql/servers/firewallRules@2021-02-01-preview' = {
  name: 'Azure Services'
  parent: sqlserver
  // Use value '0.0.0.0' for all Azure-internal IP addresses.
  properties: {
    endIpAddress: '0.0.0.0'
    startIpAddress: '0.0.0.0'
  }
}

output serverName string = sqlserverName
output dbName string = databaseName
