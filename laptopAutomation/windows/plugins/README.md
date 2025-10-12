# Plugin System

The Windows Laptop Automation system supports custom plugins to extend functionality beyond the core features.

## Plugin Structure

Each plugin consists of two files:

1. **Plugin Manifest** (`PluginName.json`) - Metadata and configuration
2. **Plugin Script** (`PluginName.ps1`) - Execution logic

## Plugin Manifest Format

```json
{
    "name": "PluginName",
    "version": "1.0.0",
    "description": "Description of what the plugin does",
    "author": "Your Name",
    "dependencies": ["Dependency1", "Dependency2"],
    "executionOrder": 100,
    "enabled": true,
    "platforms": ["Windows"],
    "minWindowsVersion": "10.0.19041",
    "parameters": {
        "parameterName": "defaultValue"
    }
}
```

### Manifest Fields

- `name`: Unique plugin identifier (must match filename)
- `version`: Semantic version string
- `description`: Human-readable description
- `author`: Plugin author name
- `dependencies`: Array of required plugins (not implemented yet)
- `executionOrder`: Numeric priority (lower numbers execute first)
- `enabled`: Whether the plugin should be loaded
- `platforms`: Supported platforms array
- `minWindowsVersion`: Minimum Windows build number
- `parameters`: Configuration parameters with defaults

## Plugin Script Format

Plugin scripts receive three parameters:

- `$Plugin`: The plugin manifest object
- `$SystemSpecs`: Hardware detection results
- `$WindowsVersion`: Windows version information
- `$Config`: Current configuration profile

```powershell
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

function Invoke-PluginExecution {
    # Your plugin logic here
    Write-Host "Executing $($Plugin.name) plugin" -ForegroundColor Cyan

    # Access parameters
    $myParam = $Plugin.parameters.parameterName

    # Access system information
    $isWindows11 = $WindowsVersion.IsWindows11
    $totalMemory = $SystemSpecs.TotalMemoryGB

    # Your installation logic here
}

Invoke-PluginExecution
```

## Available System Information

### SystemSpecs Object

- `Manufacturer`: System manufacturer
- `Model`: System model
- `TotalMemoryGB`: Total RAM in GB
- `ProcessorName`: CPU name
- `ProcessorCores`: Number of CPU cores

### WindowsVersion Object

- `Caption`: Windows version name
- `Version`: Version number
- `BuildNumber`: Build number
- `IsWindows11`: Boolean indicating Windows 11

### Config Object

- `packages`: Array of packages to install
- `includeOffice`: Boolean for Office installation
- `includeWSL`: Boolean for WSL installation
- `skipHeavyPackages`: Boolean to skip resource-intensive packages

## Plugin Development Guidelines

1. **Error Handling**: Use try/catch blocks for all external operations
2. **Logging**: Use `Write-Host` with appropriate colors for user feedback
3. **Dependencies**: Check for required tools before attempting installation
4. **Platform Checks**: Validate platform and version compatibility
5. **Idempotent**: Plugins should be safe to run multiple times
6. **Resource Aware**: Consider system resources and user preferences

## Example Plugin

See `DevelopmentTools.json` and `DevelopmentTools.ps1` for a complete example that installs additional development tools.

## Plugin Loading

Plugins are automatically discovered and loaded from this directory during setup. Disabled plugins (enabled: false) are skipped. Plugins execute in order of their executionOrder value.