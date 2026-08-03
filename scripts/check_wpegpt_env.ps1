#Requires -Version 5.0
param(
    [string]$ConfigPath,
    [switch]$AsJson,
    [switch]$NoExitCode
)

$ErrorActionPreference = 'Stop'

function suimiRead-IniLikeConfig {
    param([string]$Path)

    $config = @{}
    if (-not (Test-Path -LiteralPath $Path)) {
        return $config
    }

    Get-Content -LiteralPath $Path | ForEach-Object {
        if ($_ -match '^\s*([a-z_]+)\s*=\s*(.+?)\s*$') {
            $config[$Matches[1]] = $Matches[2].Trim()
        }
    }

    return $config
}

function suimiResolve-Python {
    param([hashtable]$Config)

    if ($Config.ContainsKey('python_path') -and
        $Config['python_path'] -ne 'auto' -and
        (Test-Path -LiteralPath $Config['python_path'])) {
        return @{
            Path = $Config['python_path']
            Source = 'config'
        }
    }

    $pythonExe = Get-Command python.exe -ErrorAction SilentlyContinue | Select-Object -First 1 -ExpandProperty Source
    if ($pythonExe) {
        return @{
            Path = $pythonExe
            Source = 'path'
        }
    }

    $pythonwExe = Get-Command pythonw.exe -ErrorAction SilentlyContinue | Select-Object -First 1 -ExpandProperty Source
    if ($pythonwExe) {
        return @{
            Path = $pythonwExe
            Source = 'path'
        }
    }

    return @{
        Path = $null
        Source = 'missing'
    }
}

function suimiTest-IdaDir {
    param([string]$Path)

    if (-not $Path -or -not (Test-Path -LiteralPath $Path)) {
        return $false
    }

    return (Test-Path -LiteralPath (Join-Path $Path 'ida.exe'))
}

function suimiResolve-IdaDir {
    param([hashtable]$Config)

    if ($Config.ContainsKey('ida_dir') -and
        $Config['ida_dir'] -ne 'auto' -and
        (suimiTest-IdaDir -Path $Config['ida_dir'])) {
        return @{
            Path = $Config['ida_dir']
            Source = 'config'
        }
    }

    foreach ($envName in @('IDA_DIR', 'IDA_PATH')) {
        $envValue = [Environment]::GetEnvironmentVariable($envName)
        if (suimiTest-IdaDir -Path $envValue) {
            return @{
                Path = $envValue
                Source = "env:$envName"
            }
        }
    }

    $idaCommand = Get-Command ida.exe -ErrorAction SilentlyContinue | Select-Object -First 1 -ExpandProperty Source
    if ($idaCommand) {
        $dir = Split-Path -Parent $idaCommand
        if (suimiTest-IdaDir -Path $dir) {
            return @{
                Path = $dir
                Source = 'path'
            }
        }
    }

    $registryPaths = @(
        'HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*',
        'HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*',
        'HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*'
    )
    foreach ($item in Get-ItemProperty $registryPaths -ErrorAction SilentlyContinue) {
        if ($item.DisplayName -notmatch 'IDA|Hex-Rays') {
            continue
        }

        foreach ($candidate in @($item.InstallLocation, (Split-Path -Parent $item.DisplayIcon -ErrorAction SilentlyContinue))) {
            if (suimiTest-IdaDir -Path $candidate) {
                return @{
                    Path = $candidate
                    Source = 'registry'
                }
            }
        }
    }

    foreach ($drive in Get-PSDrive -PSProvider FileSystem) {
        $root = $drive.Root
        $candidateDirs = Get-ChildItem -LiteralPath $root -Directory -ErrorAction SilentlyContinue |
            Where-Object { $_.Name -match 'IDA|Hex-Rays' }
        foreach ($dir in $candidateDirs) {
            if (suimiTest-IdaDir -Path $dir.FullName) {
                return @{
                    Path = $dir.FullName
                    Source = 'drive-root'
                }
            }
        }
    }

    return @{
        Path = $null
        Source = 'missing'
    }
}

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$defaultConfigPath = Join-Path $scriptDir '..\config\config.ini'
$exampleConfigPath = Join-Path $scriptDir '..\config\config.ini.example'

if (-not $ConfigPath) {
    $ConfigPath = $defaultConfigPath
}

$config = suimiRead-IniLikeConfig -Path $ConfigPath
$issues = New-Object System.Collections.Generic.List[string]
$warnings = New-Object System.Collections.Generic.List[string]

$idaDir = $null
$idaExe = $null
$ida64Exe = $null
$wpePlugin = $null
$wpeConfig = $null
$wpeController = $null

$configExists = Test-Path -LiteralPath $ConfigPath
$exampleExists = Test-Path -LiteralPath $exampleConfigPath

if (-not $configExists) {
    $issues.Add("config.ini is missing: $ConfigPath")
    if ($exampleExists) {
        $warnings.Add("Copy template first: $exampleConfigPath")
    }
}

$idaInfo = suimiResolve-IdaDir -Config $config
if ($idaInfo.Path) {
    $idaDir = $idaInfo.Path
    $idaExe = Join-Path $idaDir 'ida.exe'
    $ida64Exe = Join-Path $idaDir 'ida64.exe'
    $wpePlugin = Join-Path $idaDir 'plugins\WPeGPT.py'
    $wpeConfig = Join-Path $idaDir 'plugins\WPeGPT_Config\config.py'
    $wpeController = Join-Path $idaDir 'plugins\WPeGPT_Config\wpe_ai_controller.py'
} else {
    $issues.Add("ida_dir could not be resolved from config, environment, PATH, registry, or drive-root discovery")
}

if ($idaDir) {
    if (-not (Test-Path -LiteralPath $idaExe)) {
        $issues.Add("ida.exe not found: $idaExe")
    }
    # IDA 9 installations commonly use ida.exe for both 32-bit and 64-bit inputs.
    # wpegpt_analyze.ps1 falls back to ida.exe when ida64.exe is absent.
    if (-not (Test-Path -LiteralPath $wpePlugin)) {
        $issues.Add("WPeGPT.py not found: $wpePlugin")
    }
    if (-not (Test-Path -LiteralPath $wpeConfig)) {
        $issues.Add("WPeGPT config.py not found: $wpeConfig")
    }
    if (-not (Test-Path -LiteralPath $wpeController)) {
        $issues.Add("wpe_ai_controller.py not found: $wpeController")
    }
}

$pythonInfo = suimiResolve-Python -Config $config
if (-not $pythonInfo.Path) {
    $issues.Add("python.exe not found via config or PATH")
}

$result = [ordered]@{
    ready = ($issues.Count -eq 0)
    config_path = $ConfigPath
    config_exists = $configExists
    example_config_path = $exampleConfigPath
    example_config_exists = $exampleExists
    ida_dir = $idaDir
    ida_source = $idaInfo.Source
    ida_exe = $idaExe
    ida_exe_exists = [bool]($idaExe -and (Test-Path -LiteralPath $idaExe))
    ida64_exe = $ida64Exe
    ida64_exe_exists = [bool]($ida64Exe -and (Test-Path -LiteralPath $ida64Exe))
    wpegpt_plugin = $wpePlugin
    wpegpt_plugin_exists = [bool]($wpePlugin -and (Test-Path -LiteralPath $wpePlugin))
    wpegpt_config = $wpeConfig
    wpegpt_config_exists = [bool]($wpeConfig -and (Test-Path -LiteralPath $wpeConfig))
    wpegpt_controller = $wpeController
    wpegpt_controller_exists = [bool]($wpeController -and (Test-Path -LiteralPath $wpeController))
    python_path = $pythonInfo.Path
    python_source = $pythonInfo.Source
    issues = @($issues)
    warnings = @($warnings)
}

if ($AsJson) {
    $result | ConvertTo-Json -Depth 4
} else {
    Write-Host "WPeGPT environment check"
    Write-Host " ready      : $($result.ready)"
    Write-Host " config     : $($result.config_path)"
    Write-Host " ida_dir    : $($result.ida_dir)"
    Write-Host " python     : $($result.python_path)"
    if ($result.issues.Count -gt 0) {
        Write-Host ""
        Write-Host "Issues:"
        $result.issues | ForEach-Object { Write-Host " - $_" }
    }
    if ($result.warnings.Count -gt 0) {
        Write-Host ""
        Write-Host "Warnings:"
        $result.warnings | ForEach-Object { Write-Host " - $_" }
    }
}

if ($NoExitCode) {
    return
}

if ($result.ready) {
    exit 0
}

exit 1
