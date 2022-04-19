$appName = $args[0]
$env = $args[1]
$rg = "rg01-mitestiac-d"#("rg01-"+$appName +"-"+$env) # assuming rg naming from init
$webAppName = "func01-mitestiac-d"#("func01-"+$appName+"-"+$env) # assuming func app naming from main
$aadAppName = ($appName+"-"+$env)

# Creates new AAD Client App
$appId = az ad app create --display-name $aadAppName --query appId -o tsv # will create user_impersonation scope
#$body = ('{\"displayName\": \"'+$aadAppName+'\"}')
#write-host "body $body"
#$appId=az rest --method post --uri 'https://graph.microsoft.com/v1.0/applications'  --headers 'Content-Type=application/json' --body $body --query appId --output tsv

$objectId = az ad app show --id $appId --query objectId -o tsv
$tenantId = az account show --query tenantId -o tsv
write-host "Created app with app (client) Id: $appId"
write-host "Tenant (directory) Id: $tenantId"

# set Redirect uris for SPA, no az cli for this...
#$redirectUris = '\"http://localhost:3000\", \"http://localhost:3001\"'
$redirectUris = '\"http://localhost:7071/api/index\"'
$body = ('{\"spa\":{\"redirectUris\":['+$redirectUris+']}}')
$resp = az rest --method PATCH --uri ('https://graph.microsoft.com/v1.0/applications/' + $objectId) --headers 'Content-Type=application/json'  --body $body
write-host "set redirect uris"

# set app roles, can only be run once?
# creating app via rest will cause error "Updates to converged applications are not allowed in this version."
az ad app update --id $objectId --app-roles @app-roles.manifest.json 
write-host "app roles set"

# set app id uri
#az ad app update --id $objectId --identifier-uris ('api://'+$aadAppName)

# set access token version
$body ='{"api":{"requestedAccessTokenVersion": 2}}'
$resp = az rest --method PATCH --uri ('https://graph.microsoft.com/v1.0/applications/' + $objectId) --headers 'Content-Type=application/json'  --body $body
write-host "access token version"

# create service principal
az ad sp create --id $appId
write-host "app service principal"

# set webapp config
az webapp config appsettings set -g $rg -n $webAppName --settings AAD_CLIENTID=$appId
az webapp config appsettings set -g $rg -n $webAppName --settings AAD_TENANTID=$tenantId

# add first avail app role to currently logged in user, adapt to your needs...
$firstRoleId =  az ad app show --id $appId --query appRoles[0].id  -o tsv
$signedInUser = az ad signed-in-user show --query objectId -o tsv
$appSp = az ad sp show --id $appId --query objectId -o tsv
$body = ('{\"appRoleId\": \"'+$firstRoleId+'\",\"principalId\": \"'+$signedInUser+'\",\"resourceId\": \"'+$appSp+'\"}')
$resp = az rest --method post --uri ('https://graph.microsoft.com/v1.0/users/'+$signedInUser+'/appRoleAssignments') --headers 'Content-Type=application/json'  --body $body