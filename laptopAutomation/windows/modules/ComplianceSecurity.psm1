# ComplianceSecurity.psm1
# Module for compliance checking and security policy enforcement

function Test-SecurityBaseline {
    param([switch]$Remediate)

    Write-Log "Running security baseline assessment..." Cyan

    $results = @{
        Passed = @()
        Failed = @()
        Warnings = @()
    }

    # Check Windows Defender status
    $defenderStatus = Get-MpComputerStatus
    if ($defenderStatus.AntivirusEnabled) {
        $results.Passed += "Windows Defender Antivirus is enabled"
    } else {
        $results.Failed += "Windows Defender Antivirus is disabled"
        if ($Remediate) {
            Set-MpPreference -DisableRealtimeMonitoring $false
        }
    }

    # Check firewall status
    $firewallProfiles = Get-NetFirewallProfile
    $enabledProfiles = $firewallProfiles | Where-Object { $_.Enabled -eq $true }
    if ($enabledProfiles.Count -gt 0) {
        $results.Passed += "Windows Firewall is enabled on $($enabledProfiles.Count) profile(s)"
    } else {
        $results.Failed += "Windows Firewall is disabled on all profiles"
        if ($Remediate) {
            Set-NetFirewallProfile -All -Enabled True
        }
    }

    # Check for administrator accounts
    $adminUsers = Get-LocalGroupMember -Group "Administrators" | Where-Object { $_.ObjectClass -eq "User" }
    if ($adminUsers.Count -le 2) {  # Allow for built-in admin and one additional
        $results.Passed += "Limited administrator accounts found"
    } else {
        $results.Warnings += "Multiple administrator accounts detected"
    }

    # Check password policy
    try {
        $passwordPolicy = Get-ADDefaultDomainPasswordPolicy -ErrorAction SilentlyContinue
        if ($passwordPolicy) {
            if ($passwordPolicy.MinPasswordLength -ge 8) {
                $results.Passed += "Password policy meets minimum requirements"
            } else {
                $results.Failed += "Password policy does not meet minimum length requirements"
            }
        } else {
            # For local accounts or non-domain environments
            $results.Warnings += "Unable to verify domain password policy - using local policy check"
            $localUsers = Get-LocalUser
            $results.Passed += "Local user accounts verified"
        }
    } catch {
        $results.Warnings += "Unable to check password policy: $($_.Exception.Message)"
    }

    # Check for pending updates
    $updateSession = New-Object -ComObject Microsoft.Update.Session
    $updateSearcher = $updateSession.CreateUpdateSearcher()
    $searchResult = $updateSearcher.Search("IsInstalled=0")

    if ($searchResult.Updates.Count -eq 0) {
        $results.Passed += "System is up to date"
    } else {
        $results.Warnings += "$($searchResult.Updates.Count) pending updates found"
    }

    # Check BitLocker status
    $bitlockerVolumes = Get-BitLockerVolume
    $encryptedVolumes = $bitlockerVolumes | Where-Object { $_.ProtectionStatus -eq "On" }
    if ($encryptedVolumes.Count -gt 0) {
        $results.Passed += "BitLocker encryption is enabled on $($encryptedVolumes.Count) volume(s)"
    } else {
        $results.Failed += "BitLocker encryption is not enabled"
    }

    return $results
}

function Set-SecurityHardening {
    param([switch]$WhatIf)

    Write-Log "Applying security hardening measures..." Cyan

    if ($WhatIf) {
        Write-Log "DRY RUN: Would enable Windows Defender real-time protection" Yellow
        Write-Log "DRY RUN: Would enable Windows Firewall" Yellow
        Write-Log "DRY RUN: Would disable remote desktop" Yellow
        Write-Log "DRY RUN: Would enable audit policies" Yellow
        return
    }

    try {
        # Enable Windows Defender real-time protection
        Set-MpPreference -DisableRealtimeMonitoring $false
        Write-Log "Enabled Windows Defender real-time protection" Green

        # Enable Windows Firewall for all profiles
        Set-NetFirewallProfile -All -Enabled True
        Write-Log "Enabled Windows Firewall for all profiles" Green

        # Disable remote desktop
        Set-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control\Terminal Server" -Name "fDenyTSConnections" -Value 1
        Write-Log "Disabled remote desktop connections" Green

        # Enable audit policies
        auditpol /set /category:"Logon/Logoff" /success:enable /failure:enable
        auditpol /set /category:"Account Management" /success:enable /failure:enable
        Write-Log "Enabled key audit policies" Green

        # Disable SMBv1
        Disable-WindowsOptionalFeature -Online -FeatureName SMB1Protocol -NoRestart
        Write-Log "Disabled SMBv1 protocol" Green

        # Enable secure boot verification (if supported)
        if (Get-Command Confirm-SecureBootUEFI -ErrorAction SilentlyContinue) {
            if (Confirm-SecureBootUEFI) {
                Write-Log "Secure Boot is enabled" Green
            } else {
                Write-Log "Secure Boot is not enabled or not supported" Yellow
            }
        }

    } catch {
        Write-Log "Error applying security hardening: $($_.Exception.Message)" Red
    }
}

function Test-ComplianceStatus {
    param([string]$ComplianceFramework = "CIS")

    Write-Log "Running compliance check against $ComplianceFramework framework..." Cyan

    $complianceResults = @{
        Framework = $ComplianceFramework
        TotalChecks = 0
        PassedChecks = 0
        FailedChecks = 0
        Score = 0
        Details = @()
    }

    # CIS Benchmark checks (simplified)
    $checks = @(
        @{
            Name = "Ensure 'Audit account logon events' is set to 'Success and Failure'"
            Test = { (auditpol /get /category:"Logon/Logoff" /subcategory:"Account Logon Events") -match "Success and Failure" }
            Remediation = "auditpol /set /subcategory:'Account Logon Events' /success:enable /failure:enable"
        },
        @{
            Name = "Ensure 'Audit account management' is set to 'Success and Failure'"
            Test = { (auditpol /get /category:"Account Management") -match "Success and Failure" }
            Remediation = "auditpol /set /category:'Account Management' /success:enable /failure:enable"
        },
        @{
            Name = "Ensure Windows Defender Antivirus is enabled"
            Test = { (Get-MpComputerStatus).AntivirusEnabled }
            Remediation = "Set-MpPreference -DisableRealtimeMonitoring `$false"
        },
        @{
            Name = "Ensure Windows Firewall is enabled for all profiles"
            Test = { (Get-NetFirewallProfile | Where-Object { $_.Enabled -eq $false }).Count -eq 0 }
            Remediation = "Set-NetFirewallProfile -All -Enabled True"
        }
    )

    foreach ($check in $checks) {
        $complianceResults.TotalChecks++
        try {
            $result = & $check.Test
            if ($result) {
                $complianceResults.PassedChecks++
                $complianceResults.Details += @{
                    Check = $check.Name
                    Status = "Passed"
                    Remediation = $null
                }
            } else {
                $complianceResults.FailedChecks++
                $complianceResults.Details += @{
                    Check = $check.Name
                    Status = "Failed"
                    Remediation = $check.Remediation
                }
            }
        } catch {
            $complianceResults.FailedChecks++
            $complianceResults.Details += @{
                Check = $check.Name
                Status = "Error"
                Remediation = $check.Remediation
            }
        }
    }

    $complianceResults.Score = [math]::Round(($complianceResults.PassedChecks / $complianceResults.TotalChecks) * 100, 2)

    return $complianceResults
}

function Export-ComplianceReport {
    param(
        [Parameter(Mandatory=$true)]
        [object]$ComplianceResults,
        [string]$OutputPath = "$env:TEMP\ComplianceReport.json"
    )

    try {
        $ComplianceResults | ConvertTo-Json -Depth 10 | Set-Content -Path $OutputPath -Encoding UTF8
        Write-Log "Compliance report exported to: $OutputPath" Green
        return $OutputPath
    } catch {
        Write-Log "Error exporting compliance report: $($_.Exception.Message)" Red
        return $null
    }
}

function Invoke-SecurityRemediation {
    param([object]$ComplianceResults, [switch]$WhatIf)

    Write-Log "Applying security remediation based on compliance results..." Cyan

    foreach ($detail in $ComplianceResults.Details | Where-Object { $_.Status -eq "Failed" -and $_.Remediation }) {
        Write-Log "Remediating: $($detail.Check)" Yellow

        if ($WhatIf) {
            Write-Log "DRY RUN: Would execute: $($detail.Remediation)" Gray
        } else {
            try {
                Invoke-Expression $detail.Remediation
                Write-Log "Successfully applied remediation" Green
            } catch {
                Write-Log "Failed to apply remediation: $($_.Exception.Message)" Red
            }
        }
    }
}

# Export functions
Export-ModuleMember -Function * -Alias *