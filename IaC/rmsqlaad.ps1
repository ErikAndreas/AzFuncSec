$appName = $args[0]
$env = $args[1]

# set sqlserver admin
$rg = ("rg01-"+$appName+"-"+$env)
$sn = ("sql01-"+$appName+"-"+$env)
az sql server ad-only-auth disable --resource-group $rg --name $sn