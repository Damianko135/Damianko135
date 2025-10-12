# ProgressTracker.psm1
# Module for tracking and displaying progress during installations

class ProgressTracker {
    [int]$TotalSteps
    [int]$CurrentStep
    [string]$CurrentOperation
    [datetime]$StartTime

    ProgressTracker([int]$totalSteps) {
        $this.TotalSteps = $totalSteps
        $this.CurrentStep = 0
        $this.StartTime = Get-Date
    }

    [void]StartOperation([string]$operation) {
        $this.CurrentOperation = $operation
        $this.CurrentStep++
        $this.DisplayProgress()
    }

    [void]CompleteOperation() {
        $this.DisplayProgress($true)
    }

    [void]DisplayProgress([bool]$completed = $false) {
        $percentage = [math]::Round(($this.CurrentStep / $this.TotalSteps) * 100, 1)
        $elapsed = (Get-Date) - $this.StartTime
        $eta = if ($this.CurrentStep -gt 0) {
            $rate = $this.CurrentStep / $elapsed.TotalSeconds
            $remaining = $this.TotalSteps - $this.CurrentStep
            $etaSeconds = $remaining / $rate
            [TimeSpan]::FromSeconds($etaSeconds)
        } else {
            [TimeSpan]::Zero
        }

        $status = if ($completed) { "Completed" } else { "In Progress" }
        $etaString = if ($eta.TotalSeconds -gt 0) {
            "ETA: $($eta.ToString('hh\:mm\:ss'))"
        } else {
            "ETA: Calculating..."
        }

        Write-Progress -Activity "Windows Laptop Automation" `
                      -Status "$status - $($this.CurrentOperation)" `
                      -PercentComplete $percentage `
                      -CurrentOperation "$($this.CurrentStep)/$($this.TotalSteps) - $etaString"
    }

    [void]WriteSummary() {
        $totalTime = (Get-Date) - $this.StartTime
        Write-Log "Setup completed in $($totalTime.ToString('hh\:mm\:ss'))" Green
        Write-Log "Total operations: $($this.TotalSteps)" Gray
    }
}

function New-ProgressTracker {
    param([int]$TotalSteps)
    return [ProgressTracker]::new($TotalSteps)
}

# Export functions and classes
Export-ModuleMember -Function New-ProgressTracker
Export-ModuleMember -TypeName ProgressTracker