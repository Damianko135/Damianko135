# PluginSystem.psm1
# Module for loading and executing custom plugins

$script:LoadedPlugins = @()

function Initialize-PluginSystem {
    param([string]$PluginsPath = (Join-Path $PSScriptRoot "plugins"))

    if (-not (Test-Path $PluginsPath)) {
        Write-Log "Plugins directory not found: $PluginsPath" Yellow
        return
    }

    Write-Log "Initializing plugin system..." Cyan

    # Load plugin manifest if it exists
    $manifestPath = Join-Path $PluginsPath "plugins.json"
    if (Test-Path $manifestPath) {
        try {
            $manifest = Get-Content $manifestPath | ConvertFrom-Json
            Write-Log "Found plugin manifest with $($manifest.plugins.Count) plugins" Green

            foreach ($plugin in $manifest.plugins) {
                Import-Plugin -PluginPath (Join-Path $PluginsPath $plugin.path) -PluginConfig $plugin
            }
        } catch {
            Write-Log "Failed to load plugin manifest: $($_.Exception.Message)" Red
        }
    } else {
        # Auto-discover plugins
        Write-Log "No plugin manifest found, auto-discovering plugins..." Yellow

        $pluginFiles = Get-ChildItem $PluginsPath -Filter "*.ps1" -File
        foreach ($pluginFile in $pluginFiles) {
            Load-Plugin -PluginPath $pluginFile.FullName
        }

        $pluginModules = Get-ChildItem $PluginsPath -Filter "*.psm1" -File
        foreach ($moduleFile in $pluginModules) {
            try {
                Import-Module $moduleFile.FullName -Force
                Write-Log "Loaded plugin module: $($moduleFile.Name)" Green
                $script:LoadedPlugins += @{
                    Name = $moduleFile.BaseName
                    Type = "Module"
                    Path = $moduleFile.FullName
                }
            } catch {
                Write-Log "Failed to load plugin module $($moduleFile.Name): $($_.Exception.Message)" Red
            }
        }
    }

    Write-Log "Plugin system initialized with $($script:LoadedPlugins.Count) plugins" Green
}

function Import-Plugin {
    param([string]$PluginPath, [PSCustomObject]$PluginConfig = $null)

    if (-not (Test-Path $PluginPath)) {
        Write-Log "Plugin file not found: $PluginPath" Red
        return
    }

    try {
        $pluginName = [System.IO.Path]::GetFileNameWithoutExtension($PluginPath)

        # Load plugin script
        . $PluginPath

        $pluginInfo = @{
            Name = $pluginName
            Type = "Script"
            Path = $PluginPath
            Config = $PluginConfig
        }

        # Check if plugin has required functions
        $requiredFunctions = @("Invoke-Plugin", "Get-PluginInfo")
        $hasRequiredFunctions = $true

        foreach ($func in $requiredFunctions) {
            if (-not (Get-Command $func -ErrorAction SilentlyContinue)) {
                $hasRequiredFunctions = $false
                break
            }
        }

        if ($hasRequiredFunctions) {
            $pluginInfo.Info = Get-PluginInfo
            Write-Log "Loaded plugin: $($pluginInfo.Info.Name) v$($pluginInfo.Info.Version)" Green
            $script:LoadedPlugins += $pluginInfo
        } else {
            Write-Log "Plugin $pluginName does not have required functions (Invoke-Plugin, Get-PluginInfo)" Yellow
        }

    } catch {
        Write-Log "Failed to load plugin $PluginPath`: $($_.Exception.Message)" Red
    }
}

function Invoke-Plugins {
    param([string]$Phase, [hashtable]$Context = @{})

    if ($script:LoadedPlugins.Count -eq 0) {
        return
    }

    Write-Log "Executing plugins for phase: $Phase" Cyan

    foreach ($plugin in $script:LoadedPlugins) {
        try {
            if ($plugin.Type -eq "Script" -and (Get-Command "Invoke-Plugin" -ErrorAction SilentlyContinue)) {
                Write-Log "Running plugin: $($plugin.Info.Name)" Gray
                Invoke-Plugin -Phase $Phase -Context $Context
            }
        } catch {
            Write-Log "Plugin $($plugin.Info.Name) failed during phase $Phase`: $($_.Exception.Message)" Red
        }
    }
}

function Get-LoadedPlugins {
    return $script:LoadedPlugins
}

function New-PluginTemplate {
    param([string]$PluginName, [string]$OutputPath = ".")

    $template = @"
# $PluginName Plugin
# Description: Custom plugin for Windows Laptop Automation

function Get-PluginInfo {
    return @{
        Name = "$PluginName"
        Version = "1.0.0"
        Description = "Custom plugin description"
        Author = "Your Name"
        Phases = @("pre-install", "post-install", "cleanup")  # Supported phases
    }
}

function Invoke-Plugin {
    param([string]`$Phase, [hashtable]`$Context)

    switch (`$Phase) {
        "pre-install" {
            # Code to run before installation begins
            Write-Log "Plugin $PluginName`: Pre-install phase" Cyan
        }
        "post-install" {
            # Code to run after installation completes
            Write-Log "Plugin $PluginName`: Post-install phase" Cyan
        }
        "cleanup" {
            # Code to run during cleanup
            Write-Log "Plugin $PluginName`: Cleanup phase" Cyan
        }
        default {
            Write-Log "Plugin $PluginName`: Unknown phase `$Phase" Yellow
        }
    }
}
"@

    $outputFile = Join-Path $OutputPath "$PluginName.ps1"
    $template | Set-Content -Path $outputFile -Encoding UTF8
    Write-Log "Plugin template created: $outputFile" Green
}

# Export functions
Export-ModuleMember -Function Initialize-PluginSystem, Invoke-Plugins, Get-LoadedPlugins, New-PluginTemplate