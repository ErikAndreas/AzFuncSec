param kvName string
param miOid string 

resource accessPolicy 'Microsoft.KeyVault/vaults/accessPolicies@2021-11-01-preview' = {
  name: '${kvName}/add'
  properties: {
    accessPolicies: [
      {
      objectId: miOid  // This is the principal/objectId of our managed identity
        tenantId: subscription().tenantId
        permissions: {
          secrets: [
            'get'
          ]
        }
      }
    ]
  }
}
