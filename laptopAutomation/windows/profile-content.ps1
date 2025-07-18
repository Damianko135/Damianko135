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

Import-Module $env:ChocolateyInstall\helpers\chocolateyProfile.psm1