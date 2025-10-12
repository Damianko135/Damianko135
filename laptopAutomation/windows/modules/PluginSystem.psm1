# PluginSystem.psm1
# Module for loading and executing custom plugins

$script:LoadedPlugins = @()

function Initialize-PluginSystem {
    param([string]$PluginsPath = (Join-Path $PSScriptRoot "plugins"))

    if (-not (Test-Path $PluginsPath)) {
        Write-Log "Plugins directory not found: $PluginsPath" Yellow
        return @()
    }

    Write-Log "Initializing plugin system..." Cyan

    # Auto-discover plugins by looking for .json config files
    Write-Log "Auto-discovering plugins..." Yellow

    $pluginConfigFiles = Get-ChildItem $PluginsPath -Filter "*.json" -File
    foreach ($configFile in $pluginConfigFiles) {
        try {
            $pluginConfig = Get-Content $configFile.FullName | ConvertFrom-Json
            $pluginScriptPath = Join-Path $PluginsPath "$($configFile.BaseName).ps1"

            if (Test-Path $pluginScriptPath) {
                $pluginInfo = @{
                    Name = $configFile.BaseName
                    Type = "Script"
                    Path = $pluginScriptPath
                    Config = $pluginConfig
                    Description = $pluginConfig.description
                }

                Write-Log "Registered plugin: $($pluginInfo.Name)" Green
                $script:LoadedPlugins += $pluginInfo
            } else {
                Write-Log "Plugin script not found for config: $($configFile.Name)" Yellow
            }
        } catch {
            Write-Log "Failed to load plugin config $($configFile.Name): $($_.Exception.Message)" Red
        }
    }

    Write-Log "Plugin system initialized with $($script:LoadedPlugins.Count) plugins" Green

    return $script:LoadedPlugins
}

function Load-Plugin {
    param([string]$PluginPath)

    Import-Plugin -PluginPath $PluginPath
}

function Import-Plugin {
    param([string]$PluginPath, [PSCustomObject]$PluginConfig = $null)

    if (-not (Test-Path $PluginPath)) {
        Write-Log "Plugin file not found: $PluginPath" Red
        return
    }

    try {
        $pluginName = [System.IO.Path]::GetFileNameWithoutExtension($PluginPath)

        $pluginInfo = @{
            Name = $pluginName
            Type = "Script"
            Path = $PluginPath
            Config = $PluginConfig
        }

        # Store plugin info without loading the script yet
        Write-Log "Registered plugin: $pluginName" Green
        $script:LoadedPlugins += $pluginInfo

    } catch {
        Write-Log "Failed to load plugin $PluginPath`: $($_.Exception.Message)" Red
    }
}

function Invoke-Plugin {
    param(
        [Parameter(Mandatory=$true)]
        [PSCustomObject]$Plugin,

        [Parameter(Mandatory=$true)]
        [PSCustomObject]$SystemSpecs,

        [Parameter(Mandatory=$true)]
        [PSCustomObject]$WindowsVersion,

        [Parameter(Mandatory=$true)]
        [PSCustomObject]$Config
    )

    $pluginPath = $Plugin.Path
    if (-not (Test-Path $pluginPath)) {
        Write-Log "Plugin script not found: $pluginPath" Red
        return
    }

    try {
        Write-Log "Executing plugin: $($Plugin.Name)" Cyan

        # Execute the plugin script with parameters
        & $pluginPath -Plugin $Plugin.Config -SystemSpecs $SystemSpecs -WindowsVersion $WindowsVersion -Config $Config

        Write-Log "Plugin $($Plugin.Name) executed successfully" Green
    } catch {
        Write-Log "Failed to execute plugin $($Plugin.Name): $($_.Exception.Message)" Red
        throw
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

param(
    [Parameter(Mandatory=`$true)]
    [PSCustomObject]`$Plugin,

    [Parameter(Mandatory=`$true)]
    [PSCustomObject]`$SystemSpecs,

    [Parameter(Mandatory=`$true)]
    [PSCustomObject]`$WindowsVersion,

    [Parameter(Mandatory=`$true)]
    [PSCustomObject]`$Config
)

# Plugin execution logic
function Invoke-PluginExecution {
    Write-Host "Executing $PluginName plugin v`$($Plugin.version)" -ForegroundColor Cyan

    # Add your plugin logic here
    Write-Host "$PluginName plugin execution completed" -ForegroundColor Green
}

# Execute the plugin
Invoke-PluginExecution
"@

    $outputFile = Join-Path $OutputPath "$PluginName.ps1"
    $template | Set-Content -Path $outputFile -Encoding UTF8
    Write-Log "Plugin template created: $outputFile" Green
}

# Export functions
Export-ModuleMember -Function Initialize-PluginSystem, Invoke-Plugin, Invoke-Plugins, Get-LoadedPlugins, New-PluginTemplate