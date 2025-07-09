# Define working directory for ODT files and config
$workingDir = "$env:TEMP\OfficeInstall"

# Create working directory if it does not exist
if (-Not (Test-Path $workingDir)) {
    New-Item -Path $workingDir -ItemType Directory -Force | Out-Null
}

# Define ODT download URL and paths
$odtUrl = "https://download.microsoft.com/download/6c1eeb25-cf8b-41d9-8d0d-cc1dbc032140/officedeploymenttool_18827-20140.exe"
$odtExe = Join-Path -Path $workingDir -ChildPath "odt.exe"

# Download ODT installer
Write-Host "Downloading Office Deployment Tool..."
Invoke-WebRequest -Uri $odtUrl -OutFile $odtExe

# Extract ODT to working directory
Write-Host "Extracting Office Deployment Tool..."
Start-Process -FilePath $odtExe -ArgumentList "/extract:$workingDir /quiet" -Wait

# Create XML config content for Office 365 ProPlus 64-bit, Monthly Enterprise Channel
$configXml = @"
<Configuration>
  <Add OfficeClientEdition="64" Channel="MonthlyEnterprise">
    <Product ID="O365ProPlusRetail">
      <Language ID="en-us" />
    </Product>
  </Add>
  <Display Level="None" AcceptEULA="TRUE" />
</Configuration>
"@

# Save XML config file
$configPath = Join-Path -Path $workingDir -ChildPath "configuration.xml"
$configXml | Set-Content -Path $configPath -Encoding UTF8

# Verify config file exists
if (-Not (Test-Path $configPath)) {
    Write-Error "Configuration XML file not found at path: $configPath"
    exit 1
} else {
    Write-Host "Configuration XML created successfully at $configPath"
}

# Locate setup.exe from extracted ODT
$setupExe = Join-Path -Path $workingDir -ChildPath "setup.exe"
if (-Not (Test-Path $setupExe)) {
    Write-Error "Setup executable not found at $setupExe"
    exit 1
}

# Download Office installation files (this can take some time)
Write-Host "Downloading Office installation files. This may take a while..."
Start-Process -FilePath $setupExe -ArgumentList "/download `"$configPath`"" -Wait

# Install Office silently
Write-Host "Installing Office..."
Start-Process -FilePath $setupExe -ArgumentList "/configure `"$configPath`"" -Wait

Write-Host "Office installation process finished."
