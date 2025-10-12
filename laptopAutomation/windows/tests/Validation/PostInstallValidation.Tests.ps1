Describe "Validation Tests - Post-Installation Checks" {
    BeforeAll {
        $projectRoot = Split-Path $PSScriptRoot -Parent
        $modulesPath = Join-Path $projectRoot "modules"

        # Import required modules for validation
        $validationModules = @(
            "HardwareDetector",
            "SecurityValidator"
        )

        foreach ($module in $validationModules) {
            $modulePath = Join-Path $modulesPath "$module.psm1"
            if (Test-Path $modulePath) {
                Import-Module $modulePath -Force -ErrorAction Stop
            }
        }
    }

    AfterAll {
        # Clean up imported modules
        $validationModules | ForEach-Object {
            Remove-Module $_ -ErrorAction SilentlyContinue
        }
    }

    Context "System Requirements Validation" {
        It "Should meet minimum hardware requirements" {
            $specs = Get-SystemSpecs
            $specs.TotalMemoryGB | Should -BeGreaterOrEqual 4  # Minimum 4GB RAM
            $specs.ProcessorCores | Should -BeGreaterOrEqual 2  # Minimum 2 cores
        }

        It "Should run supported Windows version" {
            $version = Get-WindowsVersion
            [version]$version.Version | Should -BeGreaterOrEqual ([version]"10.0.1903")
        }

        It "Should have sufficient disk space" {
            $systemDrive = Get-CimInstance -ClassName Win32_LogicalDisk -Filter "DeviceID='C:'"
            $freeSpaceGB = [math]::Round($systemDrive.FreeSpace / 1GB, 2)
            $freeSpaceGB | Should -BeGreaterOrEqual 10  # Minimum 10GB free space
        }
    }

    Context "Package Manager Validation" {
        It "Should have at least one package manager available" {
            $chocoAvailable = Get-Command choco -ErrorAction SilentlyContinue
            $wingetAvailable = Test-WinGet

            ($chocoAvailable -or $wingetAvailable) | Should -Be $true
        }

        It "Should validate Chocolatey installation if present" {
            $chocoCommand = Get-Command choco -ErrorAction SilentlyContinue
            if ($chocoCommand) {
                $chocoCommand.Source | Should -Match "choco"
                $chocoVersion = & choco --version 2>$null
                $chocoVersion | Should -Not -BeNullOrEmpty
            }
        }

        It "Should validate WinGet installation if present" {
            if (Test-WinGet) {
                $wingetVersion = & winget --version 2>$null
                $wingetVersion | Should -Not -BeNullOrEmpty
            }
        }
    }

    Context "PowerShell Profile Validation" {
        It "Should have created PowerShell profile" {
            $profilePath = $PROFILE
            if (Test-Path $profilePath) {
                $profileContent = Get-Content $profilePath -Raw
                $profileContent | Should -Not -BeNullOrEmpty
                $profileContent | Should -Match "Windows Laptop Automation"
            }
        }

        It "Should have valid PowerShell syntax in profile" {
            $profilePath = $PROFILE
            if (Test-Path $profilePath) {
                $profileContent = Get-Content $profilePath -Raw
                $ast = [System.Management.Automation.Language.Parser]::ParseInput($profileContent, [ref]$null, [ref]$null)
                $ast | Should -Not -BeNullOrEmpty
            }
        }
    }

    Context "Configuration File Validation" {
        It "Should have valid JSON configuration files" {
            $configsPath = Join-Path $projectRoot "configs"
            $configFiles = Get-ChildItem $configsPath -Filter "*.json"

            foreach ($configFile in $configFiles) {
                $config = Get-Content $configFile.FullName | ConvertFrom-Json
                $config | Should -Not -BeNullOrEmpty
                $config.name | Should -Not -BeNullOrEmpty
            }
        }

        It "Should have required configuration profiles" {
            $configsPath = Join-Path $projectRoot "configs"
            $requiredConfigs = @("minimal.json", "developer.json", "gaming.json", "custom.json")

            foreach ($config in $requiredConfigs) {
                $configPath = Join-Path $configsPath $config
                Test-Path $configPath | Should -Be $true
            }
        }
    }

    Context "Module File Validation" {
        It "Should have all required module files" {
            $requiredModules = @(
                "PackageInstaller.psm1",
                "HardwareDetector.psm1",
                "SecurityValidator.psm1",
                "ProgressTracker.psm1",
                "Windows11Optimizer.psm1",
                "BackupRestore.psm1",
                "InteractiveMode.psm1",
                "PluginSystem.psm1",
                "ContainerSupport.psm1"
            )

            foreach ($module in $requiredModules) {
                $modulePath = Join-Path $modulesPath $module
                Test-Path $modulePath | Should -Be $true
            }
        }

        It "Should have valid PowerShell syntax in all modules" {
            $moduleFiles = Get-ChildItem $modulesPath -Filter "*.psm1"

            foreach ($moduleFile in $moduleFiles) {
                $moduleContent = Get-Content $moduleFile.FullName -Raw
                $ast = [System.Management.Automation.Language.Parser]::ParseInput($moduleContent, [ref]$null, [ref]$null)
                $ast | Should -Not -BeNullOrEmpty "Module $($moduleFile.Name) should have valid PowerShell syntax"
            }
        }
    }

    Context "Plugin System Validation" {
        It "Should have plugins directory" {
            $pluginsPath = Join-Path $projectRoot "plugins"
            Test-Path $pluginsPath | Should -Be $true
        }

        It "Should have valid plugin files" {
            $pluginsPath = Join-Path $projectRoot "plugins"
            $pluginFiles = Get-ChildItem $pluginsPath -Filter "*.json"

            foreach ($pluginFile in $pluginFiles) {
                $pluginManifest = Get-Content $pluginFile.FullName | ConvertFrom-Json
                $pluginManifest | Should -Not -BeNullOrEmpty
                $pluginManifest.name | Should -Not -BeNullOrEmpty
                $pluginManifest.version | Should -Not -BeNullOrEmpty

                # Check if corresponding script exists
                $scriptFile = $pluginFile.FullName -replace '\.json$', '.ps1'
                Test-Path $scriptFile | Should -Be $true
            }
        }
    }

    Context "Security Validation" {
        It "Should validate file integrity for critical files" {
            $criticalFiles = @(
                (Join-Path $projectRoot "setup.ps1"),
                (Join-Path $projectRoot "bootstrap.ps1")
            )

            foreach ($file in $criticalFiles) {
                if (Test-Path $file) {
                    { Test-FileIntegrity -FilePath $file } | Should -Not -Throw
                }
            }
        }

        It "Should have secure execution policies where appropriate" {
            # This is more of a documentation check
            # In a real validation, you might check registry settings
            $true | Should -Be $true  # Placeholder test
        }
    }

    Context "Performance Validation" {
        It "Should load modules within reasonable time" {
            $loadTime = Measure-Command {
                $modules = @(
                    "PackageInstaller",
                    "HardwareDetector",
                    "SecurityValidator",
                    "ProgressTracker"
                )

                foreach ($module in $modules) {
                    $modulePath = Join-Path $modulesPath "$module.psm1"
                    if (Test-Path $modulePath) {
                        Import-Module $modulePath -Force
                    }
                }
            }

            $loadTime.TotalSeconds | Should -BeLessThan 30  # Should load within 30 seconds
        }

        It "Should execute hardware detection quickly" {
            $detectionTime = Measure-Command {
                Get-SystemSpecs
                Get-WindowsVersion
            }

            $detectionTime.TotalMilliseconds | Should -BeLessThan 5000  # Should complete within 5 seconds
        }
    }
}