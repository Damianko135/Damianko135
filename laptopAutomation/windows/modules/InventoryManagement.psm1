# InventoryManagement.psm1
# Module for device inventory collection and reporting

function Get-SystemInventory {
    try {
        $inventory = @{
            Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            ComputerName = $env:COMPUTERNAME
            UserName = $env:USERNAME
            Domain = $env:USERDOMAIN
            OS = @{}
            Hardware = @{}
            Software = @{}
            Network = @{}
            Security = @{}
        }

        # Operating System Information
        $os = Get-WmiObject -Class Win32_OperatingSystem
        $inventory.OS = @{
            Caption = $os.Caption
            Version = $os.Version
            BuildNumber = $os.BuildNumber
            Architecture = $os.OSArchitecture
            InstallDate = $os.InstallDate
            LastBootUpTime = $os.LastBootUpTime
            Uptime = (Get-Date) - [Management.ManagementDateTimeConverter]::ToDateTime($os.LastBootUpTime)
        }

        # Hardware Information
        $cs = Get-WmiObject -Class Win32_ComputerSystem
        $bios = Get-WmiObject -Class Win32_BIOS
        $processor = Get-WmiObject -Class Win32_Processor | Select-Object -First 1
        $memory = Get-WmiObject -Class Win32_PhysicalMemory | Measure-Object -Property Capacity -Sum

        $inventory.Hardware = @{
            Manufacturer = $cs.Manufacturer
            Model = $cs.Model
            SerialNumber = $bios.SerialNumber
            BIOSVersion = $bios.Version
            Processor = @{
                Name = $processor.Name
                Cores = $processor.NumberOfCores
                LogicalProcessors = $processor.NumberOfLogicalProcessors
                MaxClockSpeed = $processor.MaxClockSpeed
            }
            Memory = @{
                TotalGB = [math]::Round($memory.Sum / 1GB, 2)
                Slots = $memory.Count
            }
        }

        # Disk Information
        $disks = Get-WmiObject -Class Win32_LogicalDisk | Where-Object { $_.DriveType -eq 3 }
        $inventory.Hardware.Disks = @()
        foreach ($disk in $disks) {
            $inventory.Hardware.Disks += @{
                Drive = $disk.DeviceID
                VolumeName = $disk.VolumeName
                FileSystem = $disk.FileSystem
                SizeGB = [math]::Round($disk.Size / 1GB, 2)
                FreeSpaceGB = [math]::Round($disk.FreeSpace / 1GB, 2)
                UsedSpaceGB = [math]::Round(($disk.Size - $disk.FreeSpace) / 1GB, 2)
                PercentUsed = [math]::Round((($disk.Size - $disk.FreeSpace) / $disk.Size) * 100, 2)
            }
        }

        # Software Information
        $installedSoftware = Get-WmiObject -Class Win32_Product | Select-Object -First 50  # Limit for performance
        $inventory.Software.InstalledApplications = @()
        foreach ($app in $installedSoftware) {
            $inventory.Software.InstalledApplications += @{
                Name = $app.Name
                Version = $app.Version
                Vendor = $app.Vendor
                InstallDate = $app.InstallDate
            }
        }

        # Network Information
        $networkAdapters = Get-WmiObject -Class Win32_NetworkAdapterConfiguration | Where-Object { $_.IPEnabled }
        $inventory.Network.Adapters = @()
        foreach ($adapter in $networkAdapters) {
            $inventory.Network.Adapters += @{
                Description = $adapter.Description
                MACAddress = $adapter.MACAddress
                IPAddress = $adapter.IPAddress
                IPSubnet = $adapter.IPSubnet
                DefaultIPGateway = $adapter.DefaultIPGateway
                DNSServerSearchOrder = $adapter.DNSServerSearchOrder
                DHCPEnabled = $adapter.DHCPEnabled
            }
        }

        # Security Information
        $inventory.Security = @{
            FirewallEnabled = (Get-NetFirewallProfile | Where-Object { $_.Enabled }).Count -gt 0
            AntivirusEnabled = (Get-MpComputerStatus).AntivirusEnabled
            BitLockerEnabled = (Get-BitLockerVolume | Where-Object { $_.ProtectionStatus -eq "On" }).Count -gt 0
            LastUpdateCheck = (Get-WindowsUpdateStatus).LastSearch
        }

        return $inventory
    } catch {
        Write-Log "Error collecting system inventory: $($_.Exception.Message)" Red
        return $null
    }
}

function Export-InventoryReport {
    param(
        [Parameter(Mandatory=$true)]
        [object]$Inventory,
        [string]$OutputPath = "$env:TEMP\SystemInventory.json",
        [switch]$IncludeSensitiveData
    )

    try {
        if (-not $IncludeSensitiveData) {
            # Remove potentially sensitive information
            $Inventory.PSObject.Properties.Remove("Security")
            $Inventory.Network.Adapters | ForEach-Object {
                $_.PSObject.Properties.Remove("MACAddress")
            }
        }

        $Inventory | ConvertTo-Json -Depth 10 | Set-Content -Path $OutputPath -Encoding UTF8
        Write-Log "Inventory report exported to: $OutputPath" Green
        return $OutputPath
    } catch {
        Write-Log "Error exporting inventory report: $($_.Exception.Message)" Red
        return $null
    }
}

function Send-InventoryToAzure {
    param(
        [Parameter(Mandatory=$true)]
        [object]$Inventory,
        [string]$WorkspaceId,
        [string]$WorkspaceKey,
        [string]$LogName = "WindowsAutomationInventory"
    )

    if (-not $WorkspaceId -or -not $WorkspaceKey) {
        Write-Log "Azure Log Analytics workspace credentials not provided" Red
        return $false
    }

    try {
        # Create the authorization signature
        $customerId = $WorkspaceId
        $sharedKey = $WorkspaceKey
        $date = [DateTime]::UtcNow.ToString("r")
        $jsonContent = $Inventory | ConvertTo-Json -Depth 10 -Compress
        $content = [Text.Encoding]::UTF8.GetBytes($jsonContent)
        $method = "POST"
        $contentType = "application/json"
        $resourceId = "/api/logs"

        $stringToHash = "$method`n$($content.Length)`n$contentType`n$date`n$resourceId"
        $bytesToHash = [Text.Encoding]::UTF8.GetBytes($stringToHash)
        $keyBytes = [Convert]::FromBase64String($sharedKey)
        $hmac = New-Object System.Security.Cryptography.HMACSHA256
        $hmac.Key = $keyBytes
        $signature = [Convert]::ToBase64String($hmac.ComputeHash($bytesToHash))

        $authorization = "SharedKey $customerId`:$signature"

        # Send the data
        $uri = "https://$customerId.ods.opinsights.azure.com$resourceId`?api-version=2016-04-01"

        $headers = @{
            "Authorization" = $authorization
            "Log-Type" = $LogName
            "x-ms-date" = $date
        }

        $response = Invoke-WebRequest -Uri $uri -Method $method -ContentType $contentType -Headers $headers -Body $content -UseBasicParsing

        if ($response.StatusCode -eq 200) {
            Write-Log "Inventory data sent to Azure Log Analytics successfully" Green
            return $true
        } else {
            Write-Log "Failed to send inventory data to Azure Log Analytics: $($response.StatusCode)" Red
            return $false
        }
    } catch {
        Write-Log "Error sending inventory to Azure: $($_.Exception.Message)" Red
        return $false
    }
}

function Get-InventoryComparison {
    param(
        [Parameter(Mandatory=$true)]
        [object]$CurrentInventory,
        [Parameter(Mandatory=$true)]
        [object]$PreviousInventory
    )

    $comparison = @{
        Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        Changes = @{
            Hardware = @()
            Software = @()
            Network = @()
            Security = @()
        }
    }

    # Compare hardware
    if ($CurrentInventory.Hardware.Model -ne $PreviousInventory.Hardware.Model) {
        $comparison.Changes.Hardware += "Hardware model changed from $($PreviousInventory.Hardware.Model) to $($CurrentInventory.Hardware.Model)"
    }

    # Compare software (simplified - check for new/missing applications)
    $currentApps = $CurrentInventory.Software.InstalledApplications | ForEach-Object { "$($_.Name) $($_.Version)" }
    $previousApps = $PreviousInventory.Software.InstalledApplications | ForEach-Object { "$($_.Name) $($_.Version)" }

    $newApps = $currentApps | Where-Object { $_ -notin $previousApps }
    $removedApps = $previousApps | Where-Object { $_ -notin $currentApps }

    if ($newApps.Count -gt 0) {
        $comparison.Changes.Software += "New applications installed: $($newApps -join ', ')"
    }
    if ($removedApps.Count -gt 0) {
        $comparison.Changes.Software += "Applications removed: $($removedApps -join ', ')"
    }

    # Compare network adapters
    $currentAdapters = $CurrentInventory.Network.Adapters | ForEach-Object { $_.Description }
    $previousAdapters = $PreviousInventory.Network.Adapters | ForEach-Object { $_.Description }

    $newAdapters = $currentAdapters | Where-Object { $_ -notin $previousAdapters }
    $removedAdapters = $previousAdapters | Where-Object { $_ -notin $currentAdapters }

    if ($newAdapters.Count -gt 0) {
        $comparison.Changes.Network += "New network adapters: $($newAdapters -join ', ')"
    }
    if ($removedAdapters.Count -gt 0) {
        $comparison.Changes.Network += "Network adapters removed: $($removedAdapters -join ', ')"
    }

    return $comparison
}

function Get-StoredInventory {
    param([string]$InventoryPath = "$env:APPDATA\WindowsAutomation\Inventory.json")

    if (Test-Path $InventoryPath) {
        try {
            $inventory = Get-Content $InventoryPath | ConvertFrom-Json
            return $inventory
        } catch {
            Write-Log "Error reading stored inventory: $($_.Exception.Message)" Red
            return $null
        }
    }

    return $null
}

function Save-Inventory {
    param(
        [Parameter(Mandatory=$true)]
        [object]$Inventory,
        [string]$InventoryPath = "$env:APPDATA\WindowsAutomation\Inventory.json"
    )

    try {
        # Create directory if it doesn't exist
        $inventoryDir = Split-Path $InventoryPath
        if (-not (Test-Path $inventoryDir)) {
            New-Item -ItemType Directory -Path $inventoryDir -Force | Out-Null
        }

        $Inventory | ConvertTo-Json -Depth 10 | Set-Content -Path $InventoryPath -Encoding UTF8
        Write-Log "Inventory saved to: $InventoryPath" Green
        return $true
    } catch {
        Write-Log "Error saving inventory: $($_.Exception.Message)" Red
        return $false
    }
}

# Export functions
Export-ModuleMember -Function * -Alias *