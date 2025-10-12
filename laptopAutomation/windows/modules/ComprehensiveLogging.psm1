#Requires -Version 5.1

<#
.SYNOPSIS
    Comprehensive logging system for Windows Laptop Automation
    Provides structured logging, searchable output, and detailed error tracking

.DESCRIPTION
    This module provides advanced logging capabilities including:
    - Structured JSON logging for searchability
    - Multiple output formats (console, file, structured)
    - Log levels and filtering
    - Performance timing
    - Error correlation and context
    - Search and analysis capabilities

.NOTES
    Author: Damian Korver
#>

# Global logging configuration
$script:LogConfig = @{
    Level = "INFO"
    ConsoleOutput = $true
    FileOutput = $true
    StructuredOutput = $true
    LogPath = "$env:TEMP\WindowsAutomation.log"
    StructuredLogPath = "$env:TEMP\WindowsAutomation.json"
    IncludeTimestamps = $true
    IncludeContext = $true
    MaxFileSizeMB = 10
    RetentionDays = 7
}

# Log levels
enum LogLevel {
    DEBUG = 0
    INFO = 1
    WARN = 2
    ERROR = 3
    FATAL = 4
}

# Initialize logging system
function Initialize-Logging {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [string]$LogPath,

        [Parameter(Mandatory=$false)]
        [string]$StructuredLogPath,

        [Parameter(Mandatory=$false)]
        [string]$Level = "INFO",

        [Parameter(Mandatory=$false)]
        [switch]$ConsoleOutput,

        [Parameter(Mandatory=$false)]
        [switch]$FileOutput,

        [Parameter(Mandatory=$false)]
        [switch]$StructuredOutput
    )

    if ($LogPath) { $script:LogConfig.LogPath = $LogPath }
    if ($StructuredLogPath) { $script:LogConfig.StructuredLogPath = $StructuredLogPath }
    if ($ConsoleOutput.IsPresent) { $script:LogConfig.ConsoleOutput = $true }
    if ($FileOutput.IsPresent) { $script:LogConfig.FileOutput = $true }
    if ($StructuredOutput.IsPresent) { $script:LogConfig.StructuredOutput = $true }

    $script:LogConfig.Level = $Level.ToUpper()

    # Create log directory if it doesn't exist
    $logDir = Split-Path $script:LogConfig.LogPath -Parent
    if (-not (Test-Path $logDir)) {
        New-Item -ItemType Directory -Path $logDir -Force | Out-Null
    }

    $structuredLogDir = Split-Path $script:LogConfig.StructuredLogPath -Parent
    if (-not (Test-Path $structuredLogDir)) {
        New-Item -ItemType Directory -Path $structuredLogDir -Force | Out-Null
    }

    # Clean up old log files
    Clear-OldLogs

    # Log initialization
    Write-StructuredLog -Level "INFO" -Message "Logging system initialized" -Context @{
        LogPath = $script:LogConfig.LogPath
        StructuredLogPath = $script:LogConfig.StructuredLogPath
        Level = $script:LogConfig.Level
    }
}

# Clean up old log files based on retention policy
function Clear-OldLogs {
    $retentionDate = (Get-Date).AddDays(-$script:LogConfig.RetentionDays)

    # Clean regular log files
    $logDir = Split-Path $script:LogConfig.LogPath -Parent
    Get-ChildItem $logDir -Filter "*.log" | Where-Object { $_.LastWriteTime -lt $retentionDate } | Remove-Item -Force

    # Clean structured log files
    $structuredLogDir = Split-Path $script:LogConfig.StructuredLogPath -Parent
    Get-ChildItem $structuredLogDir -Filter "*.json" | Where-Object { $_.LastWriteTime -lt $retentionDate } | Remove-Item -Force
}

# Check if log level should be written
function Test-LogLevel {
    param([LogLevel]$Level)

    $currentLevel = [LogLevel]::Parse([LogLevel], $script:LogConfig.Level)
    return $Level -ge $currentLevel
}

# Get caller information for context
function Get-CallerInfo {
    $caller = (Get-PSCallStack)[2]
    return @{
        ScriptName = $caller.ScriptName
        FunctionName = $caller.FunctionName
        LineNumber = $caller.ScriptLineNumber
        Command = $caller.Position.Text
    }
}

# Write structured log entry
function Write-StructuredLog {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Level,

        [Parameter(Mandatory=$true)]
        [string]$Message,

        [Parameter(Mandatory=$false)]
        [hashtable]$Context = @{},

        [Parameter(Mandatory=$false)]
        [string]$Category = "General",

        [Parameter(Mandatory=$false)]
        [switch]$NoConsole
    )

    if (-not (Test-LogLevel ([LogLevel]::Parse([LogLevel], $Level)))) {
        return
    }

    $timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ss.fffZ"
    $callerInfo = if ($script:LogConfig.IncludeContext) { Get-CallerInfo } else { $null }

    $logEntry = @{
        Timestamp = $timestamp
        Level = $Level
        Message = $Message
        Category = $Category
        Context = $Context
        Caller = $callerInfo
        SessionId = $PID
        Hostname = $env:COMPUTERNAME
        User = $env:USERNAME
    }

    # Write to structured log file
    if ($script:LogConfig.StructuredOutput -and $script:LogConfig.FileOutput) {
        try {
            $logEntryJson = $logEntry | ConvertTo-Json -Compress
            Add-Content -Path $script:LogConfig.StructuredLogPath -Value $logEntryJson -Encoding UTF8

            # Check file size and rotate if needed
            $fileSizeMB = (Get-Item $script:LogConfig.StructuredLogPath).Length / 1MB
            if ($fileSizeMB -gt $script:LogConfig.MaxFileSizeMB) {
                Move-LogFile -LogPath $script:LogConfig.StructuredLogPath
            }
        } catch {
            # Fallback to console if file logging fails
            Write-Host "Failed to write structured log: $($_.Exception.Message)" -ForegroundColor Red
        }
    }

    # Write to console if enabled
    if ($script:LogConfig.ConsoleOutput -and -not $NoConsole) {
        $color = switch ($Level) {
            "DEBUG" { "Gray" }
            "INFO" { "White" }
            "WARN" { "Yellow" }
            "ERROR" { "Red" }
            "FATAL" { "Magenta" }
            default { "White" }
        }

        $consoleMessage = if ($script:LogConfig.IncludeTimestamps) {
            "[$timestamp] [$Level] $Message"
        } else {
            "[$Level] $Message"
        }

        Write-Host $consoleMessage -ForegroundColor $color
    }

    # Write to regular log file
    if ($script:LogConfig.FileOutput) {
        try {
            $fileMessage = "[$timestamp] [$Level] [$Category] $Message"
            if ($Context.Count -gt 0) {
                $contextJson = $Context | ConvertTo-Json -Compress
                $fileMessage += " | Context: $contextJson"
            }

            Add-Content -Path $script:LogConfig.LogPath -Value $fileMessage -Encoding UTF8
        } catch {
            Write-Host "Failed to write to log file: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
}

# Rotate log file when it gets too large
function Move-LogFile {
    param([string]$LogPath)

    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $backupPath = $LogPath -replace '\.([^\.]+)$', "_$timestamp.`$1"

    try {
        Move-Item -Path $LogPath -Destination $backupPath -Force
        Write-StructuredLog -Level "INFO" -Message "Log file rotated" -Context @{ OriginalPath = $LogPath; BackupPath = $backupPath }
    } catch {
        Write-StructuredLog -Level "ERROR" -Message "Failed to rotate log file" -Context @{ Error = $_.Exception.Message }
    }
}

# Enhanced logging functions with context
function Write-DebugLog {
    param([string]$Message, [hashtable]$Context = @{}, [string]$Category = "Debug")
    Write-StructuredLog -Level "DEBUG" -Message $Message -Context $Context -Category $Category
}

function Write-InfoLog {
    param([string]$Message, [hashtable]$Context = @{}, [string]$Category = "Info")
    Write-StructuredLog -Level "INFO" -Message $Message -Context $Context -Category $Category
}

function Write-WarnLog {
    param([string]$Message, [hashtable]$Context = @{}, [string]$Category = "Warning")
    Write-StructuredLog -Level "WARN" -Message $Message -Context $Context -Category $Category
}

function Write-ErrorLog {
    param([string]$Message, [hashtable]$Context = @{}, [string]$Category = "Error")
    Write-StructuredLog -Level "ERROR" -Message $Message -Context $Context -Category $Category
}

function Write-FatalLog {
    param([string]$Message, [hashtable]$Context = @{}, [string]$Category = "Fatal")
    Write-StructuredLog -Level "FATAL" -Message $Message -Context $Context -Category $Category
}

# Performance timing functions
function Start-TimedOperation {
    param([string]$OperationName, [string]$Category = "Performance")

    $timer = @{
        Name = $OperationName
        StartTime = Get-Date
        Category = $Category
    }

    Write-DebugLog -Message "Started operation: $OperationName" -Context @{ Operation = $OperationName } -Category $Category
    return $timer
}

function Stop-TimedOperation {
    param([hashtable]$Timer)

    $endTime = Get-Date
    $duration = $endTime - $Timer.StartTime

    $context = @{
        Operation = $Timer.Name
        DurationMs = [math]::Round($duration.TotalMilliseconds, 2)
        DurationSeconds = [math]::Round($duration.TotalSeconds, 2)
        StartTime = $Timer.StartTime.ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
        EndTime = $endTime.ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
    }

    Write-InfoLog -Message "Completed operation: $($Timer.Name) in $($context.DurationSeconds)s" -Context $context -Category $Timer.Category
    return $context
}

# Search logs function
function Search-Logs {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [string]$Level,

        [Parameter(Mandatory=$false)]
        [string]$Category,

        [Parameter(Mandatory=$false)]
        [string]$MessagePattern,

        [Parameter(Mandatory=$false)]
        [DateTime]$StartDate,

        [Parameter(Mandatory=$false)]
        [DateTime]$EndDate,

        [Parameter(Mandatory=$false)]
        [int]$MaxResults = 100
    )

    $results = @()

    if (Test-Path $script:LogConfig.StructuredLogPath) {
        try {
            $logContent = Get-Content $script:LogConfig.StructuredLogPath -Raw
            $logLines = $logContent -split "`n" | Where-Object { $_ -and $_.Trim() }

            foreach ($line in $logLines) {
                try {
                    $entry = $line | ConvertFrom-Json

                    # Apply filters
                    if ($Level -and $entry.Level -ne $Level) { continue }
                    if ($Category -and $entry.Category -ne $Category) { continue }
                    if ($MessagePattern -and $entry.Message -notmatch $MessagePattern) { continue }

                    $entryDate = [DateTime]::Parse($entry.Timestamp)
                    if ($StartDate -and $entryDate -lt $StartDate) { continue }
                    if ($EndDate -and $entryDate -gt $EndDate) { continue }

                    $results += $entry

                    if ($results.Count -ge $MaxResults) { break }
                } catch {
                    # Skip malformed lines
                    continue
                }
            }
        } catch {
            Write-Warning "Failed to search structured logs: $($_.Exception.Message)"
        }
    }

    return $results
}

# Get log statistics
function Get-LogStatistics {
    $stats = @{
        TotalEntries = 0
        ByLevel = @{}
        ByCategory = @{}
        DateRange = @{}
        FileSizeMB = 0
    }

    if (Test-Path $script:LogConfig.StructuredLogPath) {
        try {
            $logContent = Get-Content $script:LogConfig.StructuredLogPath -Raw
            $logLines = $logContent -split "`n" | Where-Object { $_ -and $_.Trim() }

            $dates = @()

            foreach ($line in $logLines) {
                try {
                    $entry = $line | ConvertFrom-Json
                    $stats.TotalEntries++

                    # Count by level
                    if (-not $stats.ByLevel.ContainsKey($entry.Level)) {
                        $stats.ByLevel[$entry.Level] = 0
                    }
                    $stats.ByLevel[$entry.Level]++

                    # Count by category
                    if (-not $stats.ByCategory.ContainsKey($entry.Category)) {
                        $stats.ByCategory[$entry.Category] = 0
                    }
                    $stats.ByCategory[$entry.Category]++

                    # Track dates
                    $dates += [DateTime]::Parse($entry.Timestamp)
                } catch {
                    continue
                }
            }

            if ($dates.Count -gt 0) {
                $stats.DateRange = @{
                    Start = ($dates | Measure-Object -Minimum).Minimum
                    End = ($dates | Measure-Object -Maximum).Maximum
                }
            }

            $stats.FileSizeMB = [math]::Round((Get-Item $script:LogConfig.StructuredLogPath).Length / 1MB, 2)
        } catch {
            Write-Warning "Failed to generate log statistics: $($_.Exception.Message)"
        }
    }

    return $stats
}

# Export functions
Export-ModuleMember -Function Initialize-Logging, Write-StructuredLog, Write-DebugLog, Write-InfoLog, Write-WarnLog, Write-ErrorLog, Write-FatalLog, Start-TimedOperation, Stop-TimedOperation, Search-Logs, Get-LogStatistics