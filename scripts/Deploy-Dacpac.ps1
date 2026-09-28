[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$Dacpac,
    [Parameter(Mandatory)][string]$ServerName,
    [Parameter(Mandatory)][string]$DatabaseName,
    [Parameter(Mandatory)][string]$AccessToken,
    [string]$OutputDirectory = (Join-Path $PSScriptRoot '..\artifacts\deployment'),
    [switch]$BlockOnPossibleDataLoss
)
$ErrorActionPreference = 'Stop'
if (-not (Test-Path $Dacpac)) { throw "DACPAC not found: $Dacpac" }
$sqlPackage = (Get-Command SqlPackage -ErrorAction Stop).Source
New-Item -ItemType Directory -Force -Path $OutputDirectory | Out-Null
$connection = "Server=tcp:$ServerName.database.windows.net,1433;Initial Catalog=$DatabaseName;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"
$common = @("/SourceFile:$Dacpac", "/TargetConnectionString:$connection", "/AccessToken:$AccessToken",
    '/p:AllowDropBlockingAssemblies=False', "/p:BlockOnPossibleDataLoss=$($BlockOnPossibleDataLoss.IsPresent)",
    '/p:DropObjectsNotInSource=False')
& $sqlPackage /Action:DeployReport @common "/OutputPath:$(Join-Path $OutputDirectory 'deploy-report.xml')"
if ($LASTEXITCODE -ne 0) { throw 'DeployReport generation failed.' }
& $sqlPackage /Action:Script @common "/OutputPath:$(Join-Path $OutputDirectory 'deploy.sql')"
if ($LASTEXITCODE -ne 0) { throw 'Deployment script generation failed.' }
& $sqlPackage /Action:Publish @common "/DiagnosticsFile:$(Join-Path $OutputDirectory 'sqlpackage.log')"
if ($LASTEXITCODE -ne 0) { throw 'DACPAC publish failed.' }
