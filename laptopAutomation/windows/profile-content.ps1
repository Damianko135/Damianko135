# PowerShell Profile setup by Damian Korver

# Enable Windows Console Colors
if ($Host.Name -eq 'ConsoleHost') {
    $Host.UI.RawUI.ForegroundColor = 'White'
    $Host.UI.RawUI.BackgroundColor = 'Black'
    Clear-Host
}

# Git Aliases (using functions for proper command execution)
function gs { git status $args }
function gb { git branch $args }
function gl { git log $args }
function gc { git commit $args }
function gp { git push $args }
function gco { git checkout $args }

# General Aliases
Set-Alias ll Get-ChildItem

# Network helpers
function myip { Invoke-RestMethod http://ipinfo.io/json | Select-Object -ExpandProperty ip }
function flushdns { ipconfig /flushdns }

# Import posh-git module if installed
if (Get-Module -ListAvailable posh-git) {
    Import-Module posh-git
}

# Custom prompt
function prompt {
    "$(Get-Location)> "
}

function go-init {
    param(
        [string]$Remote = "origin"
    )

    try {
        $url = git remote get-url $Remote 2>$null
    }
    catch {
        Write-Error "No such remote: $Remote"
        return
    }

    # Normalize URL: handle both https and SSH
    if ($url -match '^https://') {
        $path = $url -replace '^https://', '' -replace '\.git$', ''
    }
    elseif ($url -match '^git@') {
        $path = $url -replace '^git@', '' -replace ':', '/' -replace '\.git$', ''
    }
    else {
        Write-Error "Unsupported remote URL format: $url"
        return
    }

    go mod init $path
}



Import-Module $env:ChocolateyInstall\helpers\chocolateyProfile.psm1