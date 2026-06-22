#!/usr/bin/env pwsh
# Sanity checks for .github/sync.yaml.
#
# Fails (non-zero exit) if:
#   - sync.yaml is missing or not valid YAML
#   - any repo entry is not in "owner/name" form
#   - any file mapping is missing a source/dest, or the source file does not exist

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Import-Module powershell-yaml

$root = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$syncPath = Join-Path $root '.github/sync.yaml'

$errors = [System.Collections.Generic.List[string]]::new()

if (-not (Test-Path $syncPath)) {
    Write-Output "::error::sync config not found at $syncPath"
    exit 1
}

try {
    $config = ConvertFrom-Yaml (Get-Content -Raw $syncPath)
}
catch {
    Write-Output "::error::sync.yaml is not valid YAML: $_"
    exit 1
}

if ($config -isnot [System.Collections.IDictionary]) {
    Write-Output "::error::sync.yaml must be a mapping at the top level"
    exit 1
}

foreach ($groupName in $config.Keys) {
    $group = $config[$groupName]
    if ($group -isnot [System.Collections.IDictionary]) {
        $errors.Add("group '$groupName' must be a mapping")
        continue
    }

    # repos: newline-delimited string or a list
    $reposRaw = $group['repos']
    $repos = @()
    if ($null -eq $reposRaw) {
        $errors.Add("group '$groupName' has no 'repos'")
    }
    elseif ($reposRaw -is [string]) {
        $repos = $reposRaw -split "`n" | ForEach-Object { $_.Trim() } | Where-Object { $_ }
    }
    elseif ($reposRaw -is [System.Collections.IEnumerable]) {
        $repos = $reposRaw | ForEach-Object { "$_".Trim() } | Where-Object { $_ }
    }
    else {
        $errors.Add("group '$groupName': 'repos' must be a list or string")
    }

    if (($null -ne $reposRaw) -and $repos.Count -eq 0) {
        $errors.Add("group '$groupName': 'repos' is empty")
    }

    foreach ($repo in $repos) {
        $parts = $repo -split '/'
        if ($parts.Count -ne 2 -or ($parts | Where-Object { -not $_ })) {
            $errors.Add("group '$groupName': repo '$repo' is not in 'owner/name' form")
        }
    }

    # files: list of {source, dest} (or shorthand strings)
    $files = $group['files']
    if ($null -eq $files) {
        $errors.Add("group '$groupName' has no 'files'")
    }
    elseif (($files -isnot [System.Collections.IEnumerable]) -or ($files -is [string])) {
        $errors.Add("group '$groupName': 'files' must be a list")
    }
    else {
        foreach ($entry in $files) {
            $source = $null
            if ($entry -is [string]) {
                $source = $entry
            }
            elseif ($entry -is [System.Collections.IDictionary]) {
                $source = $entry['source']
                if (-not $source) {
                    $errors.Add("group '$groupName': a file mapping is missing 'source'")
                    continue
                }
                if (-not $entry['dest']) {
                    $errors.Add("group '$groupName': file mapping for '$source' is missing 'dest'")
                }
            }
            else {
                $errors.Add("group '$groupName': invalid file entry")
                continue
            }

            $sourcePath = Join-Path $root $source
            if (-not (Test-Path $sourcePath)) {
                $errors.Add("group '$groupName': source file '$source' does not exist")
            }
        }
    }
}

if ($errors.Count -gt 0) {
    foreach ($err in $errors) {
        Write-Output "::error::$err"
    }
    exit 1
}

Write-Output 'sync.yaml is valid.'
