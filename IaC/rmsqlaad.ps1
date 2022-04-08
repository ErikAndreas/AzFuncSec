# running main.bicep (again) after aad.ps1 has been run will cause error ad-only auth set, run this to unset 
$appName = $args[0]
$env = $args[1]

# unset sqlserver admin
$rg = ("rg01-"+$appName+"-"+$env)
$sn = ("sql01-"+$appName+"-"+$env)
az sql server ad-only-auth disable --resource-group $rg --name $sn