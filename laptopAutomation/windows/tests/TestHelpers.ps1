# Test Helper Functions for Windows Laptop Automation Testing

# Mock functions for testing
function New-MockSystemInfo {
    return @{
        Manufacturer = "TestManufacturer"
        Model = "TestModel"
        TotalMemoryGB = 16
        ProcessorName = "Test Processor"
        ProcessorCores = 8
    }
}

function New-MockWindowsVersion {
    return @{
        Caption = "Microsoft Windows 11 Pro"
        Version = "10.0.22000"
        BuildNumber = "22000"
        IsWindows11 = $true
    }
}

function New-MockConfig {
    return @{
        name = "TestConfig"
        packages = @("git", "vscode")
        includeOffice = $false
        includeWSL = $true
        skipHeavyPackages = $false
    }
}

# Test data helpers
function Get-TestPackageList {
    return @(
        @{
            Name = "Git"
            chocoId = "git"
            wingetId = "Git.Git"
            Category = "Development"
        },
        @{
            Name = "Visual Studio Code"
            chocoId = "vscode"
            wingetId = "Microsoft.VisualStudioCode"
            Category = "Development"
        }
    )
}

function Get-TestConfigPath {
    param([string]$ConfigName = "minimal")
    return Join-Path $PSScriptRoot "..\configs\$ConfigName.json"
}

# Validation helpers
function Test-ModuleExists {
    param([string]$ModuleName, [string]$ModulesPath)

    $modulePath = Join-Path $ModulesPath "$ModuleName.psm1"
    return Test-Path $modulePath
}

function Test-ConfigFile {
    param([string]$ConfigPath)

    if (-not (Test-Path $ConfigPath)) {
        return $false
    }

    try {
        $config = Get-Content $ConfigPath | ConvertFrom-Json
        return $null -ne $config
    } catch {
        return $false
    }
}

# Cleanup helpers
function Clear-TestEnvironment {
    # Clean up any test artifacts
    $testPaths = @(
        "$env:TEMP\WindowsAutomationTest*",
        "$env:APPDATA\WindowsAutomation\Test*"
    )

    foreach ($path in $testPaths) {
        if (Test-Path $path) {
            Remove-Item $path -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}

# Assertion helpers
function Should-BeValidModule {
    param([string]$ModulePath)

    $ModulePath | Should -Exist
    $ModulePath | Should -Match "\.psm1$"

    # Test that module can be imported
    { Import-Module $ModulePath -Force -ErrorAction Stop } | Should -Not -Throw
}

function Should-BeValidJson {
    param([string]$JsonPath)

    $JsonPath | Should -Exist
    { Get-Content $JsonPath | ConvertFrom-Json } | Should -Not -Throw
}

function Should-HaveFunction {
    param([string]$ModuleName, [string]$FunctionName)

    $module = Get-Module $ModuleName
    $module.ExportedFunctions.ContainsKey($FunctionName) | Should -Be $true
}

# Performance testing helpers
function Measure-TestExecution {
    param([scriptblock]$TestScript)

    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    try {
        & $TestScript
    } finally {
        $stopwatch.Stop()
    }

    return @{
        Duration = $stopwatch.Elapsed
        TotalMilliseconds = $stopwatch.ElapsedMilliseconds
    }
}

# Export helper functions
Export-ModuleMember -Function * -Alias *