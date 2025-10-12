# SecurityValidator.psm1
# Module for security validations including checksums and secure downloads

function Get-FileHashSHA256 {
    param([string]$FilePath)

    if (-not (Test-Path $FilePath)) {
        throw "File not found: $FilePath"
    }

    try {
        $hash = Get-FileHash -Path $FilePath -Algorithm SHA256
        return $hash.Hash.ToLower()
    } catch {
        # Fallback for older PowerShell versions
        $sha256 = [System.Security.Cryptography.SHA256]::Create()
        $fileStream = [System.IO.File]::OpenRead($FilePath)
        try {
            $hashBytes = $sha256.ComputeHash($fileStream)
            return [BitConverter]::ToString($hashBytes).Replace("-", "").ToLower()
        } finally {
            $fileStream.Close()
        }
    }
}

function Test-FileIntegrity {
    param([string]$FilePath, [string]$ExpectedHash)

    if (-not (Test-Path $FilePath)) {
        Write-Log "File not found for integrity check: $FilePath" Red
        return $false
    }

    try {
        $actualHash = Get-FileHashSHA256 -FilePath $FilePath
        $match = $actualHash -eq $ExpectedHash.ToLower()

        if ($match) {
            Write-Log "File integrity verified: $FilePath" Green
        } else {
            Write-Log "File integrity check failed for $FilePath" Red
            Write-Log "Expected: $ExpectedHash" Red
            Write-Log "Actual: $actualHash" Red
        }

        return $match
    } catch {
        Write-Log "Error during integrity check: $($_.Exception.Message)" Red
        return $false
    }
}

function Invoke-SecureWebRequest {
    param([string]$Uri, [string]$OutFile, [string]$ExpectedHash = $null)

    try {
        Write-Log "Downloading securely from: $Uri" Cyan

        # Use TLS 1.2 or higher
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072

        # Disable progress bar for performance
        $oldProgressPreference = $ProgressPreference
        $ProgressPreference = 'SilentlyContinue'

        try {
            Invoke-WebRequest -Uri $Uri -OutFile $OutFile -UseBasicParsing
        } finally {
            $ProgressPreference = $oldProgressPreference
        }

        if ($ExpectedHash) {
            return Test-FileIntegrity -FilePath $OutFile -ExpectedHash $ExpectedHash
        }

        Write-Log "Download completed successfully" Green
        return $true
    } catch {
        Write-Log "Secure download failed: $($_.Exception.Message)" Red
        return $false
    }
}

function Test-CertificateValidation {
    param([string]$Uri)

    try {
        $request = [System.Net.WebRequest]::Create($Uri)
        $request.Method = "HEAD"
        $response = $request.GetResponse()
        $response.Close()
        Write-Log "Certificate validation passed for $Uri" Green
        return $true
    } catch {
        Write-Log "Certificate validation failed for $Uri : $($_.Exception.Message)" Red
        return $false
    }
}

# Export functions
Export-ModuleMember -Function Get-FileHashSHA256, Test-FileIntegrity, Invoke-SecureWebRequest, Test-CertificateValidation