#Requires -Version 5.1

<#
.SYNOPSIS
    Windows Sandbox container support for testing automation scripts.

.DESCRIPTION
    This module provides functionality to create and manage Windows Sandbox
    environments for testing the laptop automation setup in isolation.

.NOTES
    Author: Damian Korver
    Requires: Windows 10 Pro/Enterprise/Education version 1903 or later
#>

# Test if Windows Sandbox is available
function Test-WindowsSandbox {
    [CmdletBinding()]
    param()

    try {
        # Check if Windows Sandbox feature is installed
        $sandboxFeature = Get-WindowsOptionalFeature -Online -FeatureName "Containers-DisposableClientVM" -ErrorAction Stop

        if ($sandboxFeature.State -eq "Enabled") {
            Write-Verbose "Windows Sandbox is enabled"
            return $true
        } else {
            Write-Warning "Windows Sandbox is not enabled. Enable it in Windows Features."
            return $false
        }
    } catch {
        Write-Warning "Windows Sandbox is not available on this Windows edition or version."
        return $false
    }
}

# Create a Windows Sandbox configuration file
function New-SandboxConfiguration {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$ConfigPath,

        [Parameter(Mandatory=$false)]
        [string]$LogonCommand = "",

        [Parameter(Mandatory=$false)]
        [switch]$EnableNetworking,

        [Parameter(Mandatory=$false)]
        [switch]$EnableSharedFolders,

        [Parameter(Mandatory=$false)]
        [string[]]$MappedFolders,

        [Parameter(Mandatory=$false)]
        [string]$MemoryInMB = "4096",

        [Parameter(Mandatory=$false)]
        [string]$VGpu = "Default"
    )

    $configContent = @"
<Configuration>
  <VGpu>$VGpu</VGpu>
  <Networking>$($EnableNetworking.ToString().ToLower())</Networking>
  <MappedFolders>
"@

    if ($EnableSharedFolders -or $MappedFolders) {
        if ($MappedFolders) {
            foreach ($folder in $MappedFolders) {
                $configContent += @"

    <MappedFolder>
      <HostFolder>$folder</HostFolder>
      <SandboxFolder>C:\HostShare\$($folder -replace '\\', '_')</SandboxFolder>
      <ReadOnly>true</ReadOnly>
    </MappedFolder>
"@
            }
        }
    }

    $configContent += @"

  </MappedFolders>
  <LogonCommand>
    <Command>$LogonCommand</Command>
  </LogonCommand>
</Configuration>
"@

    try {
        $configContent | Out-File -FilePath $ConfigPath -Encoding UTF8 -Force
        Write-Host "Created Windows Sandbox configuration: $ConfigPath" -ForegroundColor Green
        return $true
    } catch {
        Write-Error "Failed to create sandbox configuration: $($_.Exception.Message)"
        return $false
    }
}

# Start Windows Sandbox with configuration
function Start-WindowsSandbox {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$ConfigPath,

        [Parameter(Mandatory=$false)]
        [switch]$Wait
    )

    if (-not (Test-Path $ConfigPath)) {
        Write-Error "Sandbox configuration file not found: $ConfigPath"
        return $false
    }

    if (-not (Test-WindowsSandbox)) {
        Write-Error "Windows Sandbox is not available or enabled"
        return $false
    }

    try {
        Write-Host "Starting Windows Sandbox with configuration: $ConfigPath" -ForegroundColor Cyan

        $process = Start-Process -FilePath "C:\Windows\System32\WindowsSandbox.exe" -ArgumentList "`"$ConfigPath`"" -PassThru

        if ($Wait) {
            Write-Host "Waiting for Windows Sandbox to close..." -ForegroundColor Yellow
            $process.WaitForExit()
            Write-Host "Windows Sandbox session ended" -ForegroundColor Green
        } else {
            Write-Host "Windows Sandbox started in background (PID: $($process.Id))" -ForegroundColor Green
        }

        return $true
    } catch {
        Write-Error "Failed to start Windows Sandbox: $($_.Exception.Message)"
        return $false
    }
}

# Create a test configuration for the automation setup
function New-AutomationTestSandbox {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$ProjectPath,

        [Parameter(Mandatory=$false)]
        [string]$ConfigProfile = "minimal",

        [Parameter(Mandatory=$false)]
        [string]$OutputPath = "$env:TEMP\WindowsAutomationSandbox.wsb",

        [Parameter(Mandatory=$false)]
        [switch]$EnableNetworking,

        [Parameter(Mandatory=$false)]
        [switch]$SkipPackages,

        [Parameter(Mandatory=$false)]
        [switch]$SkipProfile
    )

    # Build the logon command to run the automation
    $logonCommand = "powershell.exe -ExecutionPolicy Bypass -Command `""

    # Map the project directory
    $mappedFolders = @($ProjectPath)

    # Build the setup command
    $setupArgs = @()
    if ($SkipPackages) { $setupArgs += "-SkipPackages" }
    if ($SkipProfile) { $setupArgs += "-SkipProfile" }
    $setupArgs += "-ConfigProfile $ConfigProfile"

    $logonCommand += "cd 'C:\HostShare\$($ProjectPath -replace '\\', '_')'; "
    $logonCommand += ".\setup.ps1 $($setupArgs -join ' '); "
    $logonCommand += "Read-Host 'Press Enter to exit'"
    $logonCommand += "`""

    # Create the sandbox configuration
    $success = New-SandboxConfiguration -ConfigPath $OutputPath `
                                      -LogonCommand $logonCommand `
                                      -EnableNetworking:$EnableNetworking `
                                      -MappedFolders $mappedFolders `
                                      -MemoryInMB "8192" `
                                      -VGpu "Enable"

    if ($success) {
        Write-Host "Created automation test sandbox configuration: $OutputPath" -ForegroundColor Green
        Write-Host "Run the following command to start testing:" -ForegroundColor Cyan
        Write-Host "Start-WindowsSandbox -ConfigPath '$OutputPath'" -ForegroundColor Yellow
        return $OutputPath
    } else {
        Write-Error "Failed to create automation test sandbox"
        return $null
    }
}

# Test the automation setup in Windows Sandbox
function Test-AutomationInSandbox {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$ProjectPath,

        [Parameter(Mandatory=$false)]
        [string]$ConfigProfile = "minimal",

        [Parameter(Mandatory=$false)]
        [switch]$EnableNetworking,

        [Parameter(Mandatory=$false)]
        [switch]$SkipPackages,

        [Parameter(Mandatory=$false)]
        [switch]$SkipProfile,

        [Parameter(Mandatory=$false)]
        [switch]$Wait
    )

    $configPath = New-AutomationTestSandbox -ProjectPath $ProjectPath `
                                          -ConfigProfile $ConfigProfile `
                                          -EnableNetworking:$EnableNetworking `
                                          -SkipPackages:$SkipPackages `
                                          -SkipProfile:$SkipProfile

    if ($configPath) {
        return Start-WindowsSandbox -ConfigPath $configPath -Wait:$Wait
    } else {
        return $false
    }
}

# Export functions
Export-ModuleMember -Function Test-WindowsSandbox, New-SandboxConfiguration, Start-WindowsSandbox, New-AutomationTestSandbox, Test-AutomationInSandbox