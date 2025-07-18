# Office Deployment Automation Script
# Author: Damian Korver

$workingDir = "$env:TEMP\OfficeInstall"
$odtUrl = "https://download.microsoft.com/download/6c1eeb25-cf8b-41d9-8d0d-cc1dbc032140/officedeploymenttool_18827-20140.exe"
$odtExe = Join-Path $workingDir "odt.exe"
$setupExe = Join-Path $workingDir "setup.exe"
$configSource = Join-Path $PSScriptRoot "office-configuration.xml"
$configPath = Join-Path $workingDir "configuration.xml"

# Ensure working directory exists
if (-Not (Test-Path $workingDir)) {
    New-Item -Path $workingDir -ItemType Directory -Force | Out-Null
}

# Download ODT if not already downloaded
if (-Not (Test-Path $odtExe)) {
    Write-Host "Downloading Office Deployment Tool..."
    Invoke-WebRequest -Uri $odtUrl -OutFile $odtExe
} else {
    Write-Host "ODT already downloaded."
}

# Extract ODT if setup.exe not already present
if (-Not (Test-Path $setupExe)) {
    Write-Host "Extracting Office Deployment Tool..."
    Start-Process -FilePath $odtExe -ArgumentList "/extract:`"$workingDir`" /quiet" -Wait
} else {
    Write-Host "ODT already extracted."
}

# Copy config XML
if (-Not (Test-Path $configSource)) {
    Write-Error "Missing config file: $configSource"
    exit 1
}
Copy-Item -Path $configSource -Destination $configPath -Force
Write-Host "Using Office config from: $configSource"

# Download Office installation files
Write-Host "Downloading Office installation files (this may take a while)..."
Start-Process -FilePath $setupExe -ArgumentList "/download `"$configPath`"" -Wait

# Install Office
Write-Host "Installing Office..."
Start-Process -FilePath $setupExe -ArgumentList "/configure `"$configPath`"" -Wait

Write-Host "Office installation process finished."