[CmdletBinding()]
param(
    [string]$Project = (Join-Path $PSScriptRoot '..\database\SqlDemo.sqlproj'),
    [ValidateSet('Debug', 'Release')][string]$Configuration = 'Release',
    [string]$OutputDirectory = (Join-Path $PSScriptRoot '..\artifacts\dacpac')
)
$ErrorActionPreference = 'Stop'
$projectPath = (Resolve-Path $Project).Path
New-Item -ItemType Directory -Force -Path $OutputDirectory | Out-Null
dotnet restore $projectPath
if ($LASTEXITCODE -ne 0) { throw 'dotnet restore failed.' }
dotnet build $projectPath --configuration $Configuration --no-restore /p:NetCoreBuild=true
if ($LASTEXITCODE -ne 0) { throw 'DACPAC build failed.' }
$dacpac = Get-ChildItem (Join-Path (Split-Path $projectPath) "bin\$Configuration") -Filter *.dacpac -Recurse | Select-Object -First 1
if (-not $dacpac) { throw 'Build completed but no DACPAC was found.' }
Copy-Item $dacpac.FullName (Join-Path $OutputDirectory $dacpac.Name) -Force
Write-Output (Join-Path $OutputDirectory $dacpac.Name)
