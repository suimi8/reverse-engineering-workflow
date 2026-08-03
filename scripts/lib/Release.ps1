#Requires -Version 5.0

function suimiBump-Version {
    param(
        [string]$Version,
        [ValidateSet('patch', 'minor')]
        [string]$Bump = 'patch'
    )

    if ([string]::IsNullOrWhiteSpace($Version)) {
        throw 'Version is required.'
    }

    $parts = @($Version.Trim() -split '\.')
    while ($parts.Count -lt 3) {
        $parts += '0'
    }

    $major = [int]$parts[0]
    $minor = [int]$parts[1]
    $patch = [int]$parts[2]

    if ($Bump -eq 'minor') {
        $minor += 1
        $patch = 0
    } else {
        $patch += 1
    }

    return "$major.$minor.$patch"
}

function suimiCollect-PackageFiles {
    param(
        [string]$RootDir,
        [string[]]$ExcludeNames = @()
    )

    $resolvedRoot = (Resolve-Path -LiteralPath $RootDir).Path.TrimEnd('\', '/')
    $excludes = @('.git', '.DS_Store', 'Thumbs.db', 'desktop.ini') + $ExcludeNames

    $files = @()
    foreach ($file in Get-ChildItem -LiteralPath $resolvedRoot -File -Recurse -Force) {
        if ($file.FullName -match '\\\.git(\\|$)') {
            continue
        }

        $relative = $file.FullName.Substring($resolvedRoot.Length).TrimStart('\', '/')
        $skip = $false
        foreach ($exclude in $excludes) {
            if ($exclude -like '*\*' -and $relative -like $exclude) {
                $skip = $true
                break
            }
            if ($exclude -notlike '*\*' -and $file.Name -eq $exclude) {
                $skip = $true
                break
            }
        }
        if ($skip) {
            continue
        }

        $files += [pscustomobject]@{
            full_path     = $file.FullName
            relative_path = $relative.Replace('\', '/')
        }
    }

    return @($files)
}

function suimiNew-ReleaseZip {
    param(
        [string]$RootDir,
        [string]$ZipPath,
        [string[]]$ExcludeNames = @()
    )

    if (Test-Path -LiteralPath $ZipPath) {
        Remove-Item -LiteralPath $ZipPath -Force
    }

    $files = @(suimiCollect-PackageFiles -RootDir $RootDir -ExcludeNames $ExcludeNames)
    $zipDir = Split-Path -Parent $ZipPath
    if (-not (Test-Path -LiteralPath $zipDir)) {
        New-Item -ItemType Directory -Path $zipDir -Force | Out-Null
    }

    Add-Type -AssemblyName System.IO.Compression | Out-Null
    Add-Type -AssemblyName System.IO.Compression.FileSystem | Out-Null

    $zip = [System.IO.Compression.ZipFile]::Open($ZipPath, [System.IO.Compression.ZipArchiveMode]::Create)
    try {
        foreach ($file in $files) {
            $entry = $zip.CreateEntry($file.relative_path, [System.IO.Compression.CompressionLevel]::Optimal)
            $entryStream = $entry.Open()
            try {
                $inputStream = [System.IO.File]::OpenRead($file.full_path)
                try {
                    $inputStream.CopyTo($entryStream)
                } finally {
                    $inputStream.Dispose()
                }
            } finally {
                $entryStream.Dispose()
            }
        }
    } finally {
        $zip.Dispose()
    }

    return [pscustomobject]@{
        zip_path   = $ZipPath
        file_count = $files.Count
        bytes      = (Get-Item -LiteralPath $ZipPath).Length
        sha256     = (Get-FileHash -LiteralPath $ZipPath -Algorithm SHA256).Hash
    }
}
