#Requires -Version 5.1

<#
.SYNOPSIS
    Advanced testing framework for Windows Laptop Automation
    Runs unit tests, integration tests, and validation checks

.DESCRIPTION
    This script provides comprehensive testing capabilities for the automation system
    including unit tests for individual modules, integration tests for the full setup,
    and validation tests for installed components.

.PARAMETER TestType
    Type of tests to run: Unit, Integration, Validation, All

.PARAMETER ModuleName
    Specific module to test (for unit tests)

.PARAMETER OutputPath
    Path to save test results

.PARAMETER IncludeCoverage
    Include code coverage analysis

.EXAMPLE
    .\Run-Tests.ps1 -TestType Unit
    .\Run-Tests.ps1 -TestType All -IncludeCoverage
    .\Run-Tests.ps1 -TestType Unit -ModuleName PackageInstaller
#>

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet("Unit", "Integration", "Validation", "All")]
    [string]$TestType = "All",

    [Parameter(Mandatory=$false)]
    [string]$ModuleName,

    [Parameter(Mandatory=$false)]
    [string]$OutputPath = "$PSScriptRoot\TestResults",

    [Parameter(Mandatory=$false)]
    [switch]$IncludeCoverage
)

# Ensure Pester is available
if (-not (Get-Module -Name Pester -ListAvailable)) {
    Write-Host "Installing Pester testing framework..." -ForegroundColor Yellow
    Install-Module -Name Pester -Force -SkipPublisherCheck
}

Import-Module Pester

# Setup test environment
$testRoot = $PSScriptRoot
$projectRoot = Split-Path $testRoot -Parent
$modulesPath = Join-Path $projectRoot "modules"
$configsPath = Join-Path $projectRoot "configs"

# Create output directory
if (-not (Test-Path $OutputPath)) {
    New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
}

# Test configuration
$configuration = @{
    Run = @{
        Path = $testRoot
        PassThru = $true
        OutputPath = $OutputPath
        OutputFormat = "NUnitXml"
    }
}

if ($IncludeCoverage) {
    $configuration.Run.CodeCoverage = @{
        Path = Join-Path $modulesPath "*.psm1"
        OutputPath = Join-Path $OutputPath "coverage.xml"
        OutputFormat = "JaCoCo"
    }
}

# Import test helper functions
. (Join-Path $testRoot "TestHelpers.ps1")

# Run unit tests
function Invoke-UnitTests {
    param([string]$SpecificModule)

    Write-Host "Running Unit Tests..." -ForegroundColor Cyan

    $unitTestPath = Join-Path $testRoot "Unit"

    if ($SpecificModule) {
        $testFile = Join-Path $unitTestPath "$SpecificModule.Tests.ps1"
        if (Test-Path $testFile) {
            $result = Invoke-Pester -Script @{
                Path = $testFile
                Parameters = @{ ProjectRoot = $projectRoot }
            } @configuration.Run
        } else {
            Write-Warning "Test file not found: $testFile"
            return
        }
    } else {
        $result = Invoke-Pester -Script @{
            Path = $unitTestPath
            Parameters = @{ ProjectRoot = $projectRoot }
        } @configuration.Run
    }

    return $result
}

# Run integration tests
function Invoke-IntegrationTests {
    Write-Host "Running Integration Tests..." -ForegroundColor Cyan

    $integrationTestPath = Join-Path $testRoot "Integration"

    $result = Invoke-Pester -Script @{
        Path = $integrationTestPath
        Parameters = @{ ProjectRoot = $projectRoot }
    } @configuration.Run

    return $result
}

# Run validation tests
function Invoke-ValidationTests {
    Write-Host "Running Validation Tests..." -ForegroundColor Cyan

    $validationTestPath = Join-Path $testRoot "Validation"

    $result = Invoke-Pester -Script @{
        Path = $validationTestPath
        Parameters = @{ ProjectRoot = $projectRoot }
    } @configuration.Run

    return $result
}

# Main execution
$results = @()
$startTime = Get-Date

try {
    switch ($TestType) {
        "Unit" {
            $results += Invoke-UnitTests -SpecificModule $ModuleName
        }
        "Integration" {
            $results += Invoke-IntegrationTests
        }
        "Validation" {
            $results += Invoke-ValidationTests
        }
        "All" {
            $results += Invoke-UnitTests
            $results += Invoke-IntegrationTests
            $results += Invoke-ValidationTests
        }
    }

    # Display results summary
    $endTime = Get-Date
    $duration = $endTime - $startTime

    Write-Host "`n" + "="*50 -ForegroundColor Magenta
    Write-Host "TEST RESULTS SUMMARY" -ForegroundColor Magenta
    Write-Host "="*50 -ForegroundColor Magenta

    $totalTests = ($results | Measure-Object -Property TotalCount -Sum).Sum
    $passedTests = ($results | Measure-Object -Property PassedCount -Sum).Sum
    $failedTests = ($results | Measure-Object -Property FailedCount -Sum).Sum
    $skippedTests = ($results | Measure-Object -Property SkippedCount -Sum).Sum

    Write-Host "Total Tests: $totalTests" -ForegroundColor White
    Write-Host "Passed: $passedTests" -ForegroundColor Green
    Write-Host "Failed: $failedTests" -ForegroundColor Red
    Write-Host "Skipped: $skippedTests" -ForegroundColor Yellow
    Write-Host "Duration: $($duration.TotalSeconds.ToString("F2")) seconds" -ForegroundColor Cyan

    if ($IncludeCoverage) {
        Write-Host "`nCoverage report saved to: $(Join-Path $OutputPath "coverage.xml")" -ForegroundColor Cyan
    }

    Write-Host "Detailed results saved to: $(Join-Path $OutputPath "TestResults.xml")" -ForegroundColor Cyan

    # Exit with appropriate code
    if ($failedTests -gt 0) {
        exit 1
    } else {
        Write-Host "`nAll tests passed! ✅" -ForegroundColor Green
        exit 0
    }

} catch {
    Write-Error "Test execution failed: $($_.Exception.Message)"
    exit 1
}