#!/usr/bin/env pwsh
# PSScriptAnalyzer hook for pre-commit
# This hook validates PowerShell scripts for best practices and common issues
param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]] $Args
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# Parse arguments - pre-commit passes all file paths as positional args
$Paths = $Args
$Severity = @('Error', 'Warning')
$CustomRulePath = $null

function Ensure-PSScriptAnalyzer {
    $minVersion = "1.21.0"
    
    try {
        $module = Get-Module -ListAvailable -Name PSScriptAnalyzer | Sort-Object Version -Descending | Select-Object -First 1
        
        if ($module -and [version]$module.Version -ge [version]$minVersion) {
            Import-Module $module -Force -ErrorAction Stop
            Write-Host "Using PSScriptAnalyzer version $($module.Version)" -ForegroundColor Gray
            return
        }
    } catch {
        # Module exists but couldn't import, continue to installation
    }

    Write-Host "Installing PSScriptAnalyzer (CurrentUser scope)..." -ForegroundColor Cyan
    
    # Ensure NuGet provider and trust PSGallery to avoid interactive prompts in hooks
    if (-not (Get-PackageProvider -ListAvailable -Name NuGet -ErrorAction SilentlyContinue)) {
        Write-Host "Installing NuGet provider..." -ForegroundColor Gray
        Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -Confirm:$false -Scope CurrentUser | Out-Null
    }
    
    Set-PSRepository -Name PSGallery -InstallationPolicy Trusted -ErrorAction SilentlyContinue

    Install-Module -Name PSScriptAnalyzer -MinimumVersion $minVersion -Scope CurrentUser -Force -AllowClobber -SkipPublisherCheck -ErrorAction Stop
    Import-Module PSScriptAnalyzer -ErrorAction Stop
    Write-Host "PSScriptAnalyzer installed successfully" -ForegroundColor Green
}

if (-not $Paths -or $Paths.Count -eq 0) {
    Write-Host "No PowerShell files provided to analyze." -ForegroundColor DarkGray
    exit 0
}

try {
    Ensure-PSScriptAnalyzer
} catch {
    Write-Host "Failed to load PSScriptAnalyzer: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

$analyzerParams = @{
    Severity = $Severity
    ErrorAction = 'Continue'
}

if ($CustomRulePath -and (Test-Path $CustomRulePath)) {
    $analyzerParams['CustomRulePath'] = $CustomRulePath
}

$results = @()
$failedFiles = @()

foreach ($path in $Paths) {
    if (-not (Test-Path $path)) {
        Write-Host "Warning: File not found: $path" -ForegroundColor Yellow
        $failedFiles += $path
        continue
    }
    
    try {
        $pathResults = Invoke-ScriptAnalyzer -Path $path @analyzerParams
        if ($pathResults) {
            $results += $pathResults
        }
    } catch {
        Write-Host "Error analyzing $path : $($_.Exception.Message)" -ForegroundColor Red
        $failedFiles += $path
    }
}

if ($results -and $results.Count -gt 0) {
    Write-Host "`nPSScriptAnalyzer found $(
        if ($results.Count -eq 1) { 'an issue' } else { "$($results.Count) issues" }
    ):`n" -ForegroundColor Red
    
    $results |
        Select-Object RuleName, Severity, Line, Column, ScriptName, Message |
        Format-Table -AutoSize -Wrap | Out-String | Write-Host
    
    exit 1
}

if ($failedFiles.Count -gt 0) {
    Write-Host "Warning: Could not analyze $($failedFiles.Count) file(s)" -ForegroundColor Yellow
    exit 1
}

Write-Host "PSScriptAnalyzer: All files passed validation." -ForegroundColor Green
exit 0
