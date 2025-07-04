#!/usr/bin/env pwsh
# Bootstrap Script - Downloads zip file, extracts it, and executes PowerShell script
# Author: Damian Korver
# Description: One-line setup that fetches and executes the complete automation from GitHub

param()

# Function for timestamped logging
function Write-Log {
    param (
        [string] $Message,
        [ConsoleColor] $Color = 'White'
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$timestamp] $Message" -ForegroundColor $Color
}

Write-Log "Starting laptop automation bootstrap process..." Cyan

# Step 1: Define GitHub API URL
$apiUrl = "https://api.github.com/repos/Damianko135/Damianko135/releases/latest"
Write-Log "Fetching latest release info from GitHub API: $apiUrl" Yellow

# Step 2: Fetch latest release data
try {
    $response = Invoke-RestMethod -Uri $apiUrl -Headers @{ "User-Agent" = "laptop-automation-script" }
    Write-Log "Successfully fetched release data for tag '$($response.tag_name)'" Green
} catch {
    Write-Log "Failed to fetch release data: $($_.Exception.Message)" Red
    exit 1
}

# Step 3: Locate zip asset in the release
Write-Log "Searching for zip asset in release assets..." Yellow
$asset = $response.assets | Where-Object { $_.name -like "*.zip" }

if (-not $asset) {
    Write-Log "ERROR: No zip asset found in the latest release assets." Red
    exit 2
}

$downloadUrl = $asset.browser_download_url
$zipFilePath = Join-Path $env:TEMP "laptopAutomation.zip"

Write-Log "Found zip asset: $($asset.name)" Green
Write-Log "Preparing to download from: $downloadUrl" Yellow

# Step 4: Download the zip file
try {
    Invoke-WebRequest -Uri $downloadUrl -OutFile $zipFilePath -UseBasicParsing
    Write-Log "Zip file downloaded successfully to: $zipFilePath" Green
} catch {
    Write-Log "Failed to download zip file: $($_.Exception.Message)" Red
    exit 3
}

# Step 5: Verify download
if (-not (Test-Path $zipFilePath)) {
    Write-Log "ERROR: Zip file does not exist after download." Red
    exit 4
}

# Step 6: Extract the zip file
$extractPath = Join-Path $env:TEMP "laptopAutomation"
Write-Log "Extracting zip file to: $extractPath" Yellow

try {
    Expand-Archive -Path $zipFilePath -DestinationPath $extractPath -Force
    Write-Log "Extraction completed successfully." Green
} catch {
    Write-Log "Failed to extract zip file: $($_.Exception.Message)" Red
    exit 5
}

# Step 7: Locate and execute the PowerShell script
$scriptPath = Join-Path $extractPath "setup.ps1"
ls $scriptPath
Write-Log "Looking for automation script at: $scriptPath" Yellow

if (Test-Path $scriptPath) {
    Write-Log "Script found. Executing with bypassed execution policy..." Green
    try {
        & powershell.exe -ExecutionPolicy Bypass -File $scriptPath
        Write-Log "Script executed successfully." Green
    } catch {
        Write-Log "Failed to execute the script: $($_.Exception.Message)" Red
        exit 6
    }
    
    # Step 8: Cleanup downloaded and extracted files
    Write-Log "Cleaning up temporary files..." Yellow
    try {
        Remove-Item -Path $zipFilePath, $extractPath -Recurse -Force
        Write-Log "Cleanup completed." Green
    } catch {
        Write-Log "Failed to clean up temporary files: $($_.Exception.Message)" Red
    }

    Write-Log "Laptop automation setup completed successfully." Cyan
} else {
    Write-Log "ERROR: Script not found at expected location: $scriptPath" Red
    exit 7
}
