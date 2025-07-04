# Windows Development Environment Automation

This repository contains PowerShell scripts and modules for automating the setup of a complete Windows development environment.

## 📁 Project Structure

```
laptopAutomation/windows/
├── setup.ps1                  # Main orchestration script
├── choco.ps1                  # Legacy Chocolatey script (deprecated)
├── winget.ps1                 # Legacy WinGet script (deprecated)
├── format.ps1                 # PowerShell code formatter
├── formatter.psd1             # Formatter configuration
├── profile.ps1                # Legacy profile script (deprecated)
├── modules/                   # PowerShell modules
│   ├── Core.psm1             # Core utilities and functions
│   ├── WinGet.psm1            # WinGet package management
│   ├── Chocolatey.psm1       # Chocolatey package management
│   └── Configuration.psm1    # System configuration functions
├── packages/                  # Package installation scripts
│   ├── Install-WinGet.ps1     # WinGet package installer
│   ├── Install-Chocolatey.ps1 # Chocolatey package installer
│   ├── WinGetPackages.ps1     # WinGet package definitions
│   └── ChocolateyPackages.ps1 # Chocolatey package definitions
└── config/                    # Configuration scripts
    ├── Configure-Git.ps1      # Git configuration
    └── Configure-PowerShell.ps1 # PowerShell profile setup
```

## 🚀 Quick Start

### Prerequisites
- Windows 10/11
- PowerShell 5.1 or PowerShell 7+
- Administrator privileges

### Basic Usage

1. **Run the main setup script:**
   ```powershell
   .\setup.ps1
   ```

2. **Interactive mode (recommended for first-time users):**
   ```powershell
   .\setup.ps1 -Interactive
   ```

3. **Install specific package categories:**
   ```powershell
   .\setup.ps1 -Categories Essential,DevTools,Languages
   ```

4. **Use Chocolatey instead of WinGet:**
   ```powershell
   .\setup.ps1 -PackageManager Chocolatey
   ```

## 📦 Available Package Categories

### Essential
Core development tools needed for most development work:
- Git
- Visual Studio Code
- Windows Terminal
- PowerShell 7

### Languages
Programming languages and runtimes:
- Node.js
- Python
- .NET SDK
- Go
- Java JDK

### DevTools
Development utilities and tools:
- Docker Desktop
- GitHub Desktop
- Postman

### Utilities
General system utilities:
- 7-Zip
- Various system tools

### Additional Categories
- **Browsers**: Firefox, Chrome, Edge
- **Communication**: Teams, Discord, Slack
- **Media**: VLC, OBS, GIMP
- **Cloud**: OneDrive, Google Drive
- **Gaming**: Steam, Epic Games

## 🔧 Configuration Options

### Command Line Parameters

| Parameter | Description | Valid Values |
|-----------|-------------|--------------|
| `-PackageManager` | Choose package manager | `WinGet`, `Chocolatey` |
| `-Categories` | Package categories to install | See categories above |
| `-SkipPackages` | Skip package installation | Switch |
| `-SkipGitConfig` | Skip Git configuration | Switch |
| `-SkipProfileConfig` | Skip PowerShell profile setup | Switch |
| `-Interactive` | Show interactive menus | Switch |
| `-Help` | Show help information | Switch |

### Examples

```powershell
# Full setup with WinGet
.\setup.ps1 -PackageManager WinGet -Categories Essential,Languages,DevTools

# Skip Git configuration
.\setup.ps1 -SkipGitConfig

# Install only packages, skip configuration
.\setup.ps1 -SkipGitConfig -SkipProfileConfig

# Interactive mode
.\setup.ps1 -Interactive
```

## 🛠️ Individual Scripts

### Package Installation

#### WinGet Packages
```powershell
.\packages\Install-WinGet.ps1 -Categories Essential,DevTools
.\packages\Install-WinGet.ps1 -Interactive
```

#### Chocolatey Packages
```powershell
.\packages\Install-Chocolatey.ps1 -Categories Essential,DevTools
.\packages\Install-Chocolatey.ps1 -Interactive
```

### Configuration

#### Git Setup
```powershell
.\config\Configure-Git.ps1
.\config\Configure-Git.ps1 -UserName "John Doe" -UserEmail "john@example.com"
.\config\Configure-Git.ps1 -SkipPrompts
```

#### PowerShell Profiles
```powershell
.\config\Configure-PowerShell.ps1
.\config\Configure-PowerShell.ps1 -Force
```

## 📊 Features

### ✅ What's Automated
- **Package Installation**: Installs development tools via WinGet or Chocolatey
- **Git Configuration**: Sets up Git with user info and best practices
- **PowerShell Profiles**: Creates enhanced PowerShell profiles with aliases
- **Environment Variables**: Configures essential environment variables
- **Development Folders**: Creates standard development directory structure
- **Error Handling**: Comprehensive error handling and logging
- **Progress Tracking**: Detailed logging of all operations

### 🛡️ Safety Features
- **Administrator Check**: Ensures scripts run with proper privileges
- **Backup Creation**: Backs up existing configurations before changes
- **Rollback Capability**: Can restore previous configurations if needed
- **Dry Run Mode**: Preview changes before applying them
- **Detailed Logging**: Complete audit trail of all operations

## 🔍 Module Documentation

### Core.psm1
Provides fundamental utilities used across all scripts:
- `Test-Administrator`: Check for admin privileges
- `Assert-Administrator`: Ensure admin privileges or exit
- `Show-Banner`: Display formatted script banners
- `Get-UserChoice`: Interactive menu system
- `Test-PackageInstalled`: Generic package installation check

### WinGet.psm1
Handles WinGet package management:
- `Initialize-WinGet`: Set up WinGet package manager
- `Install-WinGetPackage`: Install single package
- `Install-WinGetPackages`: Batch package installation

### Chocolatey.psm1
Handles Chocolatey package management:
- `Initialize-Chocolatey`: Set up Chocolatey package manager
- `Install-ChocolateyPackage`: Install single package
- `Install-ChocolateyPackages`: Batch package installation

### Configuration.psm1
System and application configuration:
- `Set-GitConfiguration`: Configure Git settings
- `Set-PowerShellProfile`: Set up PowerShell profiles
- `Set-EnvironmentVariables`: Configure environment variables
- `Initialize-DevelopmentFolders`: Create development directory structure

## 🐛 Troubleshooting

### Common Issues

1. **Script Execution Policy Error**
   ```powershell
   Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
   ```

2. **Administrator Privileges Required**
   - Right-click PowerShell and select "Run as Administrator"

3. **WinGet Not Found**
   - Install App Installer from Microsoft Store
   - Update Windows to latest version

4. **Chocolatey Installation Failed**
   - Check internet connection
   - Ensure antivirus isn't blocking the installation

5. **Package Installation Timeout**
   - Some packages may take time to install
   - Check the log file for detailed error information

### Log Files
All operations are logged to: `$env:TEMP\dev-setup-{timestamp}.log`

### Getting Help
```powershell
.\setup.ps1 -Help
.\packages\Install-WinGet.ps1 -Help
.\config\Configure-Git.ps1 -Help
```

## 🔄 Maintenance

### Updating Package Lists
1. Edit `packages\WinGetPackages.ps1` or `packages\ChocolateyPackages.ps1`
2. Add new packages to appropriate categories
3. Test installation with a subset before full deployment

### Adding New Categories
1. Update the ValidateSet in script parameters
2. Add category to package definition files
3. Update help documentation

### Code Formatting
Use the included formatter to maintain code quality:
```powershell
.\format.ps1
```

## 📝 Changelog

### Recent Fixes
- ✅ Fixed string interpolation issues across all scripts
- ✅ Corrected module import paths
- ✅ Enhanced error handling and logging
- ✅ Improved PowerShell profile configuration
- ✅ Added comprehensive help documentation
- ✅ Fixed package installation validation
- ✅ Enhanced interactive mode functionality

## 🤝 Contributing
1. Test changes thoroughly in a virtual machine
2. Follow PowerShell best practices
3. Update documentation for any new features
4. Use the provided formatter for code consistency

## 📄 License
This project is licensed under the MIT License.

## 👤 Author
**Damian Korver**
- GitHub: [@Damianko135](https://github.com/Damianko135)

---

🎉 **Happy Coding!** This automation suite will help you set up a complete Windows development environment in minutes instead of hours.
