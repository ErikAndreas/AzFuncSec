/* sample invocation:
> az deployment sub create --name rgDeploy --location westeurope --template-file init.bicep --parameters <oid>

note key vaults w purge protection enabled must be purged >az keyvault purge --subscription {SUBSCRIPTION ID} -n {VAULT NAME}
>az keyvault purge --subscription <subId> -n kv01-test-d
which can't be done until after retentionperiod
*/

param oid string // current logged in user objectId >az ad signed-in-user show --query objectId
param appName string = 'mitestiac'
param resourceGroupLocation string = 'westeurope'
param env string = 'd'

targetScope = 'subscription'

resource rg 'Microsoft.Resources/resourceGroups@2021-01-01' = {
  name: 'rg01-${appName}-${env}' 
  location: resourceGroupLocation
}

module kv './kv.bicep' = {
  name: 'kv'
  scope: rg
  params: {
    oid: oid
    name: 'kv01-${appName}-${env}'
    env: env
    loc: rg.location
  }
}

