$here = Split-Path -Parent $MyInvocation.MyCommand.Path
. (Join-Path $here '..\scripts\lib\Release.ps1')

Describe 'suimiBump-Version' {
    It 'bumps patch by one' {
        (suimiBump-Version -Version '1.23.0' -Bump 'patch') | Should Be '1.23.1'
    }

    It 'bumps minor and resets patch' {
        (suimiBump-Version -Version '1.23.4' -Bump 'minor') | Should Be '1.24.0'
    }

    It 'pads a two-part version before bumping' {
        (suimiBump-Version -Version '1.23' -Bump 'patch') | Should Be '1.23.1'
    }

    It 'throws on an empty version' {
        $threw = $false
        try {
            suimiBump-Version -Version '' | Out-Null
        } catch {
            $threw = $true
        }
        $threw | Should Be $true
    }
}

Describe 'suimiCollect-PackageFiles' {
    It 'excludes the release zip, .git and OS junk' {
        $tempRoot = Join-Path ([System.IO.Path]::GetTempPath()) ('re_pkg_' + [guid]::NewGuid().ToString('N'))
        New-Item -ItemType Directory -Path $tempRoot -Force | Out-Null
        try {
            New-Item -ItemType Directory -Path (Join-Path $tempRoot '.git') -Force | Out-Null
            New-Item -ItemType File -Path (Join-Path $tempRoot 'reverse-engineering-workflow.zip') -Force | Out-Null
            New-Item -ItemType File -Path (Join-Path $tempRoot '.DS_Store') -Force | Out-Null
            New-Item -ItemType File -Path (Join-Path $tempRoot 'Thumbs.db') -Force | Out-Null
            New-Item -ItemType File -Path (Join-Path $tempRoot 'keep.md') -Force | Out-Null

            $files = @(suimiCollect-PackageFiles -RootDir $tempRoot -ExcludeNames @('reverse-engineering-workflow.zip'))
            @($files).Count | Should Be 1
            $files[0].relative_path | Should Be 'keep.md'
        } finally {
            Remove-Item -LiteralPath $tempRoot -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}

Describe 'suimiNew-ReleaseZip' {
    It 'creates a zip containing the packaged files' {
        $tempRoot = Join-Path ([System.IO.Path]::GetTempPath()) ('re_zip_' + [guid]::NewGuid().ToString('N'))
        New-Item -ItemType Directory -Path $tempRoot -Force | Out-Null
        try {
            New-Item -ItemType File -Path (Join-Path $tempRoot 'a.md') -Force | Out-Null
            New-Item -ItemType Directory -Path (Join-Path $tempRoot 'sub') -Force | Out-Null
            New-Item -ItemType File -Path (Join-Path $tempRoot 'sub\b.ps1') -Force | Out-Null

            $zipPath = Join-Path $tempRoot 'out.zip'
            $info = suimiNew-ReleaseZip -RootDir $tempRoot -ZipPath $zipPath -ExcludeNames @('out.zip')

            (Test-Path -LiteralPath $zipPath) | Should Be $true
            $info.file_count | Should Be 2

            Add-Type -AssemblyName System.IO.Compression.FileSystem | Out-Null
            $zip = [System.IO.Compression.ZipFile]::OpenRead($zipPath)
            try {
                $names = @($zip.Entries | ForEach-Object { $_.FullName })
                ($names -contains 'a.md') | Should Be $true
                ($names -contains 'sub/b.ps1') | Should Be $true
            } finally {
                $zip.Dispose()
            }
        } finally {
            Remove-Item -LiteralPath $tempRoot -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}