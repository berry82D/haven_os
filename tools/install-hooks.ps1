# Installs the Law 16 pre-commit hook into .git/hooks (local-only, not versioned).
# Run after a fresh clone or moving PCs:  .\tools\install-hooks.ps1
$ErrorActionPreference = 'Stop'
$src = Join-Path $PSScriptRoot 'pre-commit.sh'
$gitDir = git rev-parse --absolute-git-dir
$dst = Join-Path $gitDir 'hooks/pre-commit'
$text = [System.IO.File]::ReadAllText($src) -replace "`r`n", "`n"
[System.IO.File]::WriteAllText($dst, $text, (New-Object System.Text.UTF8Encoding($false)))
Write-Host ('Pre-commit hook installed at ' + $dst)