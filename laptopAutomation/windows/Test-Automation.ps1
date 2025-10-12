# Windows Laptop Automation - Test Suite
# Tests all components of the automation system

param(
    [switch]$QuickTest,
    [switch]$PluginTest,
    [switch]$ConfigTest
)

Write-Host "=== Windows Laptop Automation Test Suite ===" -ForegroundColor Cyan
Write-Host ""

function Test-SetupWhatIf {
    Write-Host "Testing setup.ps1 WhatIf mode..." -ForegroundColor Yellow

    $testCases = @(
        @{ Name = "Default config"; Params = "-WhatIf -SkipPackages -SkipProfile" },
        @{ Name = "Minimal config"; Params = "-WhatIf -SkipPackages -SkipProfile -ConfigProfile minimal" },
        @{ Name = "Gaming config"; Params = "-WhatIf -SkipPackages -SkipProfile -ConfigProfile gaming" },
        @{ Name = "Custom config"; Params = "-WhatIf -SkipPackages -SkipProfile -ConfigProfile custom" }
    )

    foreach ($test in $testCases) {
        Write-Host "  Testing: $($test.Name)" -ForegroundColor Gray
        try {
            $command = "powershell.exe -ExecutionPolicy Bypass -Command `"& { .\setup.ps1 $($test.Params) }`""
            $result = Invoke-Expression $command 2>&1

            if ($LASTEXITCODE -eq 0) {
                Write-Host "    ✓ Passed" -ForegroundColor Green
            } else {
                Write-Host "    ✗ Failed (Exit code: $LASTEXITCODE)" -ForegroundColor Red
            }
        } catch {
            Write-Host "    ✗ Exception: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
}

function Test-PluginSystem {
    Write-Host "Testing plugin system..." -ForegroundColor Yellow

    if (-not (Test-Path "plugins")) {
        Write-Host "  ✗ Plugins directory not found" -ForegroundColor Red
        return
    }

    $pluginConfigs = Get-ChildItem "plugins\*.json" -ErrorAction SilentlyContinue
    Write-Host "  Found $($pluginConfigs.Count) plugin config(s)" -ForegroundColor Gray

    foreach ($config in $pluginConfigs) {
        Write-Host "    Testing plugin: $($config.BaseName)" -ForegroundColor Gray

        $scriptFile = Join-Path "plugins" "$($config.BaseName).ps1"
        if (Test-Path $scriptFile) {
            Write-Host "      ✓ Script file exists" -ForegroundColor Green
        } else {
            Write-Host "      ✗ Script file missing: $scriptFile" -ForegroundColor Red
        }

        try {
            $configData = Get-Content $config.FullName | ConvertFrom-Json
            if ($configData.name -and $configData.version) {
                Write-Host "      ✓ Valid plugin configuration" -ForegroundColor Green
            } else {
                Write-Host "      ✗ Invalid configuration" -ForegroundColor Red
            }
        } catch {
            Write-Host "      ✗ Invalid JSON: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
}

function Test-ConfigurationFiles {
    Write-Host "Testing configuration files..." -ForegroundColor Yellow

    if (-not (Test-Path "configs")) {
        Write-Host "  ✗ Configs directory not found" -ForegroundColor Red
        return
    }

    $configFiles = Get-ChildItem "configs\*.json"
    Write-Host "  Found $($configFiles.Count) configuration file(s)" -ForegroundColor Gray

    foreach ($config in $configFiles) {
        Write-Host "    Testing config: $($config.BaseName)" -ForegroundColor Gray

        try {
            $configData = Get-Content $config.FullName | ConvertFrom-Json
            if ($configData.name -and $configData.description) {
                Write-Host "      ✓ Valid configuration" -ForegroundColor Green
            } else {
                Write-Host "      ✗ Invalid configuration" -ForegroundColor Red
            }
        } catch {
            Write-Host "      ✗ Invalid JSON: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
}

# Run tests
if ($QuickTest -or (-not ($PluginTest -or $ConfigTest))) {
    Write-Host "Running quick test suite..." -ForegroundColor Cyan
    Test-SetupWhatIf
    Test-PluginSystem
    Test-ConfigurationFiles
}

if ($PluginTest) {
    Test-PluginSystem
}

if ($ConfigTest) {
    Test-ConfigurationFiles
}

Write-Host ""
Write-Host "=== Test Suite Complete ===" -ForegroundColor Cyan