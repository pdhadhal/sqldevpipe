<# 
import a database from a blob container in another subsciption
 #>

[CmdletBinding()]
param (
    [string] $environment, # to environment
    [string] $tenantid,
    [string] $production_subscriptionid,
    [string] $production_spn_clientid,
    [string] $production_spn_secret,
    [string] $subscriptionid,
    [string] $spn_clientid,
    [string] $spn_secret,
    [string] $skuname
)

If ($environment -eq $null){
    $environment = "DEV";
}
Write-Host "************************************************"
Write-Host "variables"
Write-Host "************************************************"
$resourcegroup1 = "AUAZE-$environment-DEMO"
$production_resourcegroup1 = "AUAZE-PRD-DEMO"
$sqlserver1 = "AUAZE-$environment-DEMO-dbsvrp1".ToLower()
$keyvaultname = "au-DEMO-$environment-1".ToLower()    
$backups = 'backups'
$filename = "DEMO_PRD_$(Get-Date -Format "yyyy-MM-dd").bacpac" ###            YOU CAN ONLY IMPORT TODAYS PRODUCTION EXPORT
$bloburi = "https://backups.blob.core.windows.net/bacpac/$filename" 

### PRODUCTION
Write-Host "************************************************"
Write-Host "login via spn to production and get the container key"
Write-Host "************************************************"
az login --service-principal --username $production_spn_clientid --password $production_spn_secret --tenant $tenantid
$keyvalue = az storage account keys list -g $production_resourcegroup1 -n $backups --subscription $production_subscriptionid --query '[0].value' -o json
az logout --username $production_spn_clientid

### DEV or UAT 
Write-Host "************************************************"
Write-Host "login to dev or uat"
Write-Host "************************************************" 
az login --service-principal --username $spn_clientid --password $spn_secret --tenant $tenantid
$sqladmin = az keyvault secret show --name 'sqladmin' --vault-name $keyvaultname --query 'value' 
$sqlpassword = az keyvault secret show --name 'sqlpassword' --vault-name $keyvaultname --query 'value' 
Write-Host "************************************************"
Write-Host "import bacpac from production to blob container"
Write-Host "************************************************" 
az account set --subscription $subscriptionid
az sql db delete -g $resourcegroup1 -s $sqlserver1 -n "DEMO" --yes
az sql db create -g $resourcegroup1 -s $sqlserver1 -n "DEMO" --service-objective $skuname
az sql db import -s $sqlserver1 -n "DEMO" -g $resourcegroup1 -u $sqladmin -p $sqlpassword  --auth-type SQL --storage-uri $bloburi --storage-key-type "StorageAccessKey" --storage-key "$keyvalue"   