param functionAppName string
param location string
param planId string

resource functionApp 'Microsoft.Web/sites@2020-12-01' = {
  name: functionAppName
  location: location
  kind: 'functionapp'
  properties: {
    httpsOnly: true
    serverFarmId: planId
  }
  identity: {
    type: 'SystemAssigned'
  }
}

output fnAppTenantId string = functionApp.identity.tenantId
output fnAppPrincipalId string = functionApp.identity.principalId
