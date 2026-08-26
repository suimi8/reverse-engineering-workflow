#Requires -Version 5.0
param(
    [switch]$Quiet
)

$ErrorActionPreference = 'Stop'
$testsDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$rootDir = (Resolve-Path -LiteralPath (Join-Path $testsDir '..')).Path

$pester = @(Get-Module -ListAvailable -Name Pester | Sort-Object Version -Descending) | Select-Object -First 1
# 测试脚本使用 dot-source 加载共享函数，与 Pester 4/5 的 ScriptScope 兼容最佳；
# Pester 6 引入独立 ScriptScope 会导致 dot-source 的函数不可见，故优先选 3.x/4.x/5.x。
$pester45 = @(Get-Module -ListAvailable -Name Pester | Where-Object { $_.Version.Major -ge 3 -and $_.Version.Major -le 5 } | Sort-Object Version -Descending) | Select-Object -First 1
if ($pester45) { $pester = $pester45 }
if (-not $pester) {
    if ($Quiet) {
        Write-Output 'SKIP:Pester is not installed.'
        exit 0
    }
    Write-Host 'Pester is not installed. Install it with: Install-Module Pester -Scope CurrentUser -Force'
    exit 1
}

try {
    Import-Module -Name $pester.Name -RequiredVersion $pester.Version -Force -ErrorAction Stop
} catch {
    if ($Quiet) {
        Write-Output "SKIP:Pester $($pester.Version) failed to load."
        exit 0
    }
    Write-Host "Pester $($pester.Version) failed to load: $($_.Exception.Message)"
    exit 1
}

$testFiles = @(Get-ChildItem -LiteralPath $testsDir -Filter '*.Tests.ps1' -File | Select-Object -ExpandProperty FullName)
if ($testFiles.Count -eq 0) {
    Write-Output 'FAIL:no test files found in tests/'
    exit 1
}

$pesterMajor = [int]$pester.Version.Major
if ($pesterMajor -le 3) {
    $quietArgs = @{ Quiet = $true }
} elseif ($pesterMajor -ge 6) {
    $quietArgs = @{ Output = if ($Quiet) { 'None' } else { 'Normal' } }
} else {
    $quietArgs = @{ Show = if ($Quiet) { 'None' } else { 'All' } }
}

$invokeArgs = @{
    Script   = $testFiles
    PassThru = $true
}
# Pester 6+ removed -Script; use -Path instead
if ($pesterMajor -ge 6) {
    $invokeArgs = @{
        Path     = $testFiles
        PassThru = $true
    }
}
$result = Invoke-Pester @invokeArgs @quietArgs

$passed = 0
$failed = 0
if ($null -ne $result.Result) {
    $passed = [int]$result.PassedCount
    $failed = [int]$result.FailedCount
    $ok = ($result.Result -eq 'Passed')
} else {
    $passed = [int]$result.PassedCount
    $failed = [int]$result.FailedCount
    $ok = ($failed -eq 0)
}

if ($Quiet) {
    if ($ok) {
        Write-Output "PASS:passed=$passed"
    } else {
        Write-Output "FAIL:failed=$failed passed=$passed"
        exit 1
    }
    exit 0
}

Write-Host "Pester $($pester.Version) run finished: passed=$passed failed=$failed"
if ($ok) {
    exit 0
}
exit 1
