[CmdletBinding()]
param([string]$Root = (Join-Path $PSScriptRoot '..\database'))
$ErrorActionPreference = 'Stop'
$files = Get-ChildItem $Root -Filter *.sql -Recurse
if (-not $files) { throw 'No SQL files found.' }
$violations = @()
foreach ($file in $files) {
    $text = Get-Content $file.FullName -Raw
    if ($text -match '(?im)^\s*(DROP\s+(DATABASE|TABLE)|TRUNCATE\s+TABLE)\b') {
        $violations += "$($file.FullName): destructive statement is not allowed"
    }
    if ($text -match '(?i)\bGRANT\s+CONTROL\s+TO\b|\bdb_owner\b') {
        $violations += "$($file.FullName): excessive privilege detected"
    }
}
if ($violations) { $violations | Write-Error; throw 'SQL policy validation failed.' }
if (Get-Command sqlfluff -ErrorAction SilentlyContinue) {
    & sqlfluff lint $Root --dialect tsql
    if ($LASTEXITCODE -ne 0) { throw 'sqlfluff lint failed.' }
} else {
    Write-Warning 'sqlfluff is unavailable; structural safety checks passed.'
}
