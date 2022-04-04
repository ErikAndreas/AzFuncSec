param saName string
param sku string
param location string = resourceGroup().location
param softDelete bool
param kvName string = ''
param keysToVault bool = false
param allowSharedKeyAccess bool = true

resource stg 'Microsoft.Storage/storageAccounts@2021-04-01' = {
  name: saName
  location: location
  sku: {
    name: sku
  }
  kind: 'StorageV2'
  properties:{
    minimumTlsVersion:'TLS1_2'
    allowSharedKeyAccess: allowSharedKeyAccess
  }
}

// https://docs.microsoft.com/en-us/azure/templates/microsoft.storage/storageaccounts/blobservices?tabs=bicep
resource stgPolicy 'Microsoft.Storage/storageAccounts/blobServices@2021-04-01' = {
  parent: stg
  name: 'default'
  properties: {
    containerDeleteRetentionPolicy: {
      days:7
      enabled: softDelete
    }
    deleteRetentionPolicy: {
      days:7
      enabled:softDelete
    }
  }
}


resource keyVault 'Microsoft.KeyVault/vaults@2021-11-01-preview' existing = {
  name: kvName
}

resource stConnStrSecret 'Microsoft.KeyVault/vaults/secrets@2021-11-01-preview' = if (keysToVault) {  // Type of the resource is just "secret"
  name: '${saName}ConnStr'  // Secret name, only one segment
  parent: keyVault
  properties: {
    value: 'DefaultEndpointsProtocol=https;AccountName=${stg.name};EndpointSuffix=${environment().suffixes.storage};AccountKey=${listKeys(stg.id, stg.apiVersion).keys[0].value}'
  }
}

resource stKeySecret 'Microsoft.KeyVault/vaults/secrets@2021-11-01-preview' = if (keysToVault)  {
  name: '${saName}Key'  // Secret name, only one segment
  parent: keyVault
  properties: {
    value: listKeys(stg.id, stg.apiVersion).keys[0].value
  }
}

//output storageConnectionString string = 'DefaultEndpointsProtocol=https;AccountName=${stg.name};EndpointSuffix=${environment().suffixes.storage};AccountKey=${listKeys(stg.id, stg.apiVersion).keys[0].value}'
//output storageKey string = listKeys(stg.id, stg.apiVersion).keys[0].value
output storageName string = stg.name
