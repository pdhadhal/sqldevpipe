<# 

sanitise database
remove any production data or permissions
#>

[CmdletBinding()]
param (
    [string] $environment,
    [string] $tenantid,
    [string] $subscriptionid,
    [string] $spn_clientid,
    [string] $spn_secret
)
# powershell sql module
if (-not (Get-Command Invoke-Sqlcmd -ErrorAction SilentlyContinue)) {
    Write-Error "Unabled to find Invoke-SqlCmd cmdlet"
    install-module sqlserver
    update-module sqlserver
}

if (-not (Get-Module -Name SqlServer | Where-Object {$_.ExportedCommands.Count -gt 0})) {
    Write-Error "The SqlServer module is not loaded"
    Import-Module SqlServer -ErrorAction Stop
}

if (-not (Get-Module -ListAvailable | Where-Object Name -eq SqlServer)) {
    Write-Error "Can't find the SqlServer module"
    install-module sqlserver
    update-module sqlserver
    Import-Module SqlServer -ErrorAction Stop
}

### LOGIN
az login --service-principal --username $spn_clientid --password $spn_secret --tenant $tenantid
$keyvaultname = "au-key-$environment-1".ToLower()   
# get SQL Server admin credentials from key vault
$sqladmin = az keyvault secret show --name 'sqladmin' --vault-name $keyvaultname --query 'value' 
$sqlpassword = az keyvault secret show --name 'sqlpassword' --vault-name $keyvaultname --query 'value' 

# build sql to clean emails
$sql += "UPDATE contact SET email ='sanitised@test.com'"
$sql += "`n"
$sql += "UPDATE contact SET phone ='0444444444'"
$sql += "`n"

# execute SQL against database
Invoke-SqlCmd -ServerInstance "tcp:auaze-$environment-demo.database.windows.net" -Database "AUAZE-$environment-DEMO" -Username "$sqladmin" -Password $sqlpassword -Query $sql

