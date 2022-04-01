param name string
param oid string
param env string = 'd'
param loc string = resourceGroup().location

// creating a key vault with current user oid 
resource kv 'Microsoft.KeyVault/vaults@2021-11-01-preview' = {
  name: name
  location: loc
  properties: {
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: subscription().tenantId
    accessPolicies: [
      {
        objectId: oid
        tenantId: subscription().tenantId
        permissions: {
          secrets: [
            'all'
          ]
        }
      }
    ]
    enabledForTemplateDeployment: true
    enablePurgeProtection: ('p' == env) ? true : true // true for prod, setting false not possible due to bug in rest api???
    enableSoftDelete: ('p' == env) ? true : false // true for prod
    softDeleteRetentionInDays: ('p' == env) ? 90 : 7 // >= 7 && <= 90
  }
}
