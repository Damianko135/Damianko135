# Windows Laptop Automation

A comprehensive PowerShell-based automation script for setting up a Windows development environment.

## Features

- **Automated Package Installation**: Installs essential development tools and applications
- **Dual Package Manager Support**: Uses Chocolatey as primary, WinGet as fallback
- **PowerShell Profile Configuration**: Sets up aliases, functions, and custom prompt
- **Organized Configuration**: Profile content separated for easy maintenance
- **Permission Handling**: Automatic administrator privilege verification
- **Error Handling**: Comprehensive error handling and logging

## Files Structure

- `setup.ps1` - Main setup script that orchestrates the entire installation process
- `profile.ps1` - Legacy profile setup script (now uses external content file)
- `profile-content.txt` - PowerShell profile content (aliases, functions, prompt)
- `packageList.json` - List of packages to install with both Chocolatey and WinGet IDs
- `packageManagers.json` - Package manager configuration
- `README.md` - This documentation file

## Quick Start

### Prerequisites

- Windows 10/11
- PowerShell 7.0 or later
- Administrator privileges

### Installation

1. **Clone or download** this repository to your local machine
2. **Open PowerShell as Administrator**
3. **Navigate** to the script directory
4. **Run the setup script**:

```powershell
# Full setup (recommended)
.\setup.ps1

# Skip package installation
.\setup.ps1 -SkipPackages

# Skip profile setup
.\setup.ps1 -SkipProfile

# Force overwrite existing profile
.\setup.ps1 -Force
   .\setup.ps1
   ```

That's it! The script will handle everything automatically.

## ✨ What It Does

The script performs the following steps automatically:

### 1. **Administrator Privileges**
- Checks for admin privileges
- Automatically restarts as administrator if needed

### 2. **Package Manager Setup**
- Installs and configures **WinGet**
- Installs and configures **Chocolatey**
- Ensures both are properly added to PATH

### 3. **Software Installation**
- Installs packages from `packageList.json`
- Tries WinGet first, falls back to Chocolatey
- Shows progress and handles errors gracefully

### 4. **PowerShell Profile Setup**
- Creates a custom PowerShell profile with useful aliases
- Adds Git shortcuts and network utilities
- Sets up proper encoding and default location

## 📦 Default Packages

If no `packageList.json` file exists, the script creates one with these essential packages:

- **Git** - Version control system
- **Visual Studio Code** - Code editor
- **PowerShell 7** - Modern PowerShell
- **Windows Terminal** - Modern terminal application
- **7-Zip** - File compression utility
- **Mozilla Firefox** - Web browser
- **PowerToys** - Windows utilities
- **Node.js** - JavaScript runtime

## 🛠️ Customization

### Adding/Removing Packages

Edit the `packageList.json` file to customize which packages get installed:

```json
[
    {
        "Name": "Package Display Name",
        "Id": "WinGet.Package.ID",
        "choco": "chocolatey-package-name"
    }
]
```

### PowerShell Profile Features

The script sets up these useful aliases and functions:

- **`ll`** - List files (Get-ChildItem)
- **`grep`** - Search text (Select-String)
- **`which`** - Find command (Get-Command)
- **`gs`** - Git status
- **`gl`** - Git log (pretty format)
- **`gb`** - Git branches
- **`Get-ProcessPort`** - Find what's using a port
- **`Edit-Profile`** - Edit PowerShell profile

## 🔧 Features

- ✅ **Single Script** - Everything in one file
- ✅ **Automatic Admin Elevation** - Handles permissions automatically
- ✅ **Progress Tracking** - Shows installation progress
- ✅ **Error Handling** - Graceful error handling and reporting
- ✅ **Fallback Support** - WinGet → Chocolatey fallback
- ✅ **Default Package List** - Creates sensible defaults if none exist
- ✅ **Profile Setup** - Useful PowerShell aliases and functions

## 📋 Requirements

- Windows 10 or Windows 11
- PowerShell 5.1 or later
- Internet connection
- Administrator privileges (script will request if needed)

## 🎯 Usage Examples

### Basic Usage
```powershell
# Run the complete setup
.\setup.ps1
```

### Check What Would Be Installed
```powershell
# View the package list
Get-Content packageList.json | ConvertFrom-Json | Format-Table Name, Id, choco
```

### Customize Before Running
```powershell
# Edit the package list first
notepad packageList.json
# Then run setup
.\setup.ps1
```

## 🔍 Troubleshooting

### Common Issues

1. **"Execution policy" error**
   ```powershell
   Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
   ```

2. **Package installation fails**
   - Check internet connection
   - Verify package IDs in `packageList.json`
   - Some packages might require specific Windows versions

3. **PowerShell profile not loading**
   - Restart PowerShell after setup
   - Check profile location: `$PROFILE.AllUsersCurrentHost`

### Getting Help

The script provides detailed output showing:
- Which packages were successfully installed
- Which packages failed and why
- Where files were created
- Next steps after completion

## � Project Files

This project consists of several PowerShell scripts and configuration files that work together to provide a complete Windows environment setup:

### Core Scripts

#### `setup.ps1`
The main entry point script that orchestrates the entire setup process. It:
- Ensures administrator privileges
- Sets up package managers (WinGet and Chocolatey)
- Calls the package installation script
- Sets up the PowerShell profile
- Provides comprehensive logging and error handling

#### `installPackages.ps1`
Handles the automated installation of software packages. Features:
- Reads package definitions from `packageList.json`
- Attempts installation via WinGet first, falls back to Chocolatey
- Automatically elevates to administrator if needed
- Provides detailed logging for each installation attempt
- Gracefully handles installation failures

#### `profile.ps1`
Creates and configures a custom PowerShell profile with:
- Git aliases (gs, gb, gl, gc, gp, gco)
- Useful system aliases (ll for Get-ChildItem)
- Network utility functions (myip, flushdns)
- Custom prompt configuration
- Support for Force overwrite or Append modes

#### `ensureAdmin.ps1`
Utility script for checking and ensuring administrator privileges:
- Tests current user's administrator status
- Automatically restarts scripts with elevated permissions when needed
- Used by other scripts that require admin access

#### `packageManagers.ps1`
Manages the installation and configuration of package managers:
- Ensures WinGet is installed and functional
- Installs Chocolatey if not present
- Upgrades existing package managers to latest versions
- Verifies package manager functionality

### Configuration Files

#### `packageList.json`
Defines the software packages to be installed. Each entry contains:
- `Name`: Display name for the package
- `wingetId`: WinGet package identifier
- `chocoId`: Chocolatey package name (fallback)
- Supports both WinGet and Chocolatey package sources

#### `packageManagers.json`
Configuration file for package manager settings and preferences:
- Package manager priorities and fallback rules
- Installation preferences and default arguments
- Source repository configurations

### File Dependencies

```
setup.ps1 (main entry point)
├── ensureAdmin.ps1 (admin privilege checking)
├── packageManagers.ps1 (package manager setup)
├── installPackages.ps1 (software installation)
│   └── packageList.json (package definitions)
├── profile.ps1 (PowerShell profile setup)
└── packageManagers.json (package manager config)
```

All scripts are designed to work independently but are orchestrated by `setup.ps1` for the complete automated setup experience.

## �📝 Author

Damian Korver

## 📄 License

This project is open source and available under the MIT License.