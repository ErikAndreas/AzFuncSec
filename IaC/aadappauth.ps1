# Creates new AAD Client App
#$redirectUris = '\"http://localhost:3000\", \"http://localhost:3001\"'
$redirectUris = '\"http://localhost:7071/api/index\"'
$appId = az ad app create --display-name mitestiac --query appId
$objectId = az ad app show --id $appId --query objectId -o tsv
$tenantId = az account show --query tenantId -o tsv
write-host "Created app with app (client) Id: $appId"
write-host "Tenant (directory) Id: $tenantId"

# set Redirect uris for SPA, no az cli for this...
$body = ('{\"spa\":{\"redirectUris\":['+$redirectUris+']}}')
$resp = az rest --method PATCH --uri ('https://graph.microsoft.com/v1.0/applications/' + $objectId) --headers 'Content-Type=application/json'  --body $body

# set app roles, can only be run once?
#az ad app update --id $objectId --app-roles @app-roles.manifest.json

# set app id uri
az ad app update --id $objectId --identifier-uris 'api://mitestiac-d'

# set access token version
$body ='{"api":{"requestedAccessTokenVersion": 2}}'
$resp = az rest --method PATCH --uri ('https://graph.microsoft.com/v1.0/applications/' + $objectId) --headers 'Content-Type=application/json'  --body $body