# Windows11Optimizer.psm1
# Module for Windows 11 specific optimizations and configurations

function Enable-Windows11Features {
    $windowsVersion = Get-WindowsVersion

    if (-not $windowsVersion.IsWindows11) {
        Write-Log "Not Windows 11, skipping Windows 11 optimizations" Yellow
        return
    }

    Write-Log "Applying Windows 11 optimizations..." Cyan

    # Enable auto HDR if supported
    try {
        if (Get-Command Set-WindowsAutoHDR -ErrorAction SilentlyContinue) {
            Set-WindowsAutoHDR -Enable
            Write-Log "Auto HDR enabled" Green
        }
    } catch {
        Write-Log "Auto HDR not supported or failed to enable: $($_.Exception.Message)" Yellow
    }

    # Configure snap layouts
    try {
        # Enable snap layouts in taskbar
        $registryPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
        Set-ItemProperty -Path $registryPath -Name "EnableSnapAssistFlyout" -Value 1 -Type DWord
        Write-Log "Snap layouts enabled" Green
    } catch {
        Write-Log "Failed to enable snap layouts: $($_.Exception.Message)" Yellow
    }

    # Enable dynamic refresh rate if supported
    try {
        $displayPath = "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers"
        if (Test-Path $displayPath) {
            Set-ItemProperty -Path $displayPath -Name "EnableDynamicRefreshRate" -Value 1 -Type DWord
            Write-Log "Dynamic refresh rate enabled" Green
        }
    } catch {
        Write-Log "Failed to enable dynamic refresh rate: $($_.Exception.Message)" Yellow
    }
}

function Install-WSL2Integration {
    $windowsVersion = Get-WindowsVersion

    if (-not $windowsVersion.IsWindows11) {
        Write-Log "WSL2 integration requires Windows 11" Yellow
        return
    }

    try {
        Write-Log "Setting up WSL2 integration..." Cyan

        # Enable WSL feature
        dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
        dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart

        # Set WSL2 as default
        wsl --set-default-version 2

        Write-Log "WSL2 integration setup completed" Green
    } catch {
        Write-Log "Failed to setup WSL2 integration: $($_.Exception.Message)" Red
    }
}

function Optimize-WindowsPackageManager {
    $windowsVersion = Get-WindowsVersion

    if (-not $windowsVersion.IsWindows11) {
        Write-Log "Advanced WinGet features require Windows 11" Yellow
        return
    }

    try {
        Write-Log "Optimizing Windows Package Manager..." Cyan

        # Enable experimental features in WinGet
        winget settings --enable LocalManifestFiles
        winget settings --enable ExperimentalFeatures

        Write-Log "Windows Package Manager optimized" Green
    } catch {
        Write-Log "Failed to optimize Windows Package Manager: $($_.Exception.Message)" Yellow
    }
}

function Set-Windows11Settings {
    $windowsVersion = Get-WindowsVersion

    if (-not $windowsVersion.IsWindows11) {
        Write-Log "Windows 11 settings not applicable" Yellow
        return
    }

    try {
        Write-Log "Configuring Windows 11 specific settings..." Cyan

        # Disable widgets on taskbar (optional - can be enabled if desired)
        $registryPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
        Set-ItemProperty -Path $registryPath -Name "TaskbarDa" -Value 0 -Type DWord

        # Enable dark mode
        Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name "AppsUseLightTheme" -Value 0 -Type DWord
        Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name "SystemUsesLightTheme" -Value 0 -Type DWord

        Write-Log "Windows 11 settings configured" Green
    } catch {
        Write-Log "Failed to configure Windows 11 settings: $($_.Exception.Message)" Yellow
    }
}

# Export functions
Export-ModuleMember -Function Enable-Windows11Features, Install-WSL2Integration, Optimize-WindowsPackageManager, Set-Windows11Settings