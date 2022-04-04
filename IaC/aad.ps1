# might need to run >Set-Executionpolicy Bypass -Scope Process before running this script

# create group and add func app + currently logged in user
$appName = $args[0]
$env = $args[1]
$groupName=($appName+"-"+$env+"-sec")
$servicePrincipal = az ad sp list --display-name func01-mitestiac-d --query [0].objectId # $args[2]
az ad group create --display-name $groupName --mail-nickname $groupName
az ad group member add --group $groupName --member-id $servicePrincipal
$signedInUser = az ad signed-in-user show --query objectId
az ad group member add --group $groupName --member-id $signedInUser

# give group needed roles to storage, will take some before in effect
$groupId = az ad group show --group $groupName --query objectId
az role assignment create --assignee $groupId --role "Storage Blob Data Owner"
az role assignment create --assignee $groupId --role "Storage Queue Data Contributor"

# create group for SQLServer admins and add currently logged in user
$sqlAdminGroupName=($appName+"-"+$env+"-sqladmins")
az ad group create --display-name $sqlAdminGroupName --mail-nickname $sqlAdminGroupName
az ad group member add --group $sqlAdminGroupName --member-id $signedInUser

# set sqlserver admin
$rg = ("rg01-"+$appName+"-"+$env)
$sn = ("sql01-"+$appName+"-"+$env)
$sqlGroupName = az ad group show --group $sqlAdminGroupName --query objectId -o tsv
az sql server ad-admin create --resource-group $rg --server $sn --object-id $sqlGroupName -u $sqlAdminGroupName # all params seems to, contrary to docs, be required
az sql server ad-only-auth enable --resource-group $rg --name $sn