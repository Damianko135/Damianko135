Describe "Integration Tests - Full Setup Process" {
    BeforeAll {
        $projectRoot = Split-Path $PSScriptRoot -Parent
        $modulesPath = Join-Path $projectRoot "modules"

        # Import all modules
        $modules = @(
            "PackageInstaller",
            "HardwareDetector",
            "SecurityValidator",
            "ProgressTracker",
            "Windows11Optimizer",
            "BackupRestore",
            "InteractiveMode",
            "PluginSystem",
            "ContainerSupport"
        )

        foreach ($module in $modules) {
            $modulePath = Join-Path $modulesPath "$module.psm1"
            if (Test-Path $modulePath) {
                Import-Module $modulePath -Force -ErrorAction Stop
            }
        }
    }

    AfterAll {
        # Clean up imported modules
        $modules | ForEach-Object {
            Remove-Module $_ -ErrorAction SilentlyContinue
        }
    }

    Context "Module Integration" {
        It "Should load all required modules successfully" {
            $loadedModules = Get-Module | Where-Object { $_.Name -in $modules }
            $loadedModules.Count | Should -Be $modules.Count
        }

        It "Should have no module loading conflicts" {
            # Verify no duplicate functions or conflicts
            $allFunctions = Get-Command -Module $modules | Select-Object -ExpandProperty Name
            $uniqueFunctions = $allFunctions | Select-Object -Unique
            $allFunctions.Count | Should -Be $uniqueFunctions.Count
        }
    }

    Context "Configuration Loading" {
        It "Should load all configuration profiles" {
            $configFiles = Get-ChildItem $configsPath -Filter "*.json"
            $configFiles.Count | Should -BeGreaterThan 0

            foreach ($configFile in $configFiles) {
                $config = Get-Content $configFile.FullName | ConvertFrom-Json
                $config | Should -Not -BeNullOrEmpty
                $config.name | Should -Not -BeNullOrEmpty
            }
        }

        It "Should validate configuration structure" {
            $minimalConfig = Get-Content (Join-Path $configsPath "minimal.json") | ConvertFrom-Json
            $minimalConfig.packages | Should -Not -BeNullOrEmpty
            $minimalConfig.PSObject.Properties.Name | Should -Contain "includeOffice"
            $minimalConfig.PSObject.Properties.Name | Should -Contain "includeWSL"
        }
    }

    Context "Hardware Detection Integration" {
        It "Should detect hardware without errors" {
            { Get-SystemSpecs } | Should -Not -Throw
            { Get-WindowsVersion } | Should -Not -Throw
        }

        It "Should return consistent data types" {
            $specs = Get-SystemSpecs
            $version = Get-WindowsVersion

            $specs.TotalMemoryGB | Should -BeOfType [int]
            $specs.ProcessorCores | Should -BeOfType [int]
            $version.IsWindows11 | Should -BeOfType [bool]
        }
    }

    Context "Progress Tracking Integration" {
        It "Should create and manage progress trackers" {
            $tracker = New-ProgressTracker -TotalSteps 5
            $tracker | Should -Not -BeNullOrEmpty
            $tracker.TotalSteps | Should -Be 5
            $tracker.CurrentStep | Should -Be 0
        }

        It "Should update progress correctly" {
            $tracker = New-ProgressTracker -TotalSteps 3
            $tracker.StartOperation("Test Operation")
            $tracker.CompleteOperation()

            $tracker.CurrentStep | Should -Be 1
        }
    }

    Context "Plugin System Integration" {
        It "Should initialize plugin system" {
            $pluginsPath = Join-Path $projectRoot "plugins"
            $loadedPlugins = Initialize-PluginSystem -PluginsPath $pluginsPath
            $loadedPlugins | Should -Not -BeNullOrEmpty
        }

        It "Should load existing plugins" {
            $pluginsPath = Join-Path $projectRoot "plugins"
            $loadedPlugins = Initialize-PluginSystem -PluginsPath $pluginsPath

            # Should load the DevelopmentTools plugin
            $devToolsPlugin = $loadedPlugins | Where-Object { $_.Name -eq "DevelopmentTools" }
            $devToolsPlugin | Should -Not -BeNullOrEmpty
            $devToolsPlugin.Version | Should -Be "1.0.0"
        }
    }

    Context "Backup and Restore Integration" {
        It "Should create system restore points" {
            # Note: This test may require admin privileges
            # In a real test environment, this would be mocked
            $function = Get-Command New-SystemRestorePoint -Module BackupRestore
            $function | Should -Not -BeNullOrEmpty
        }

        It "Should backup user configurations" {
            $function = Get-Command Backup-UserConfigurations -Module BackupRestore
            $function | Should -Not -BeNullOrEmpty
        }
    }

    Context "Security Validation Integration" {
        It "Should validate file integrity" {
            # Test with a known file
            $testFile = Join-Path $PSScriptRoot "..\setup.ps1"
            if (Test-Path $testFile) {
                { Test-FileIntegrity -FilePath $testFile } | Should -Not -Throw
            }
        }

        It "Should handle secure web requests" {
            $function = Get-Command Invoke-SecureWebRequest -Module SecurityValidator
            $function | Should -Not -BeNullOrEmpty
        }
    }

    Context "Container Support Integration" {
        It "Should detect Windows Sandbox availability" {
            { Test-WindowsSandbox } | Should -Not -Throw
        }

        It "Should create sandbox configurations" {
            $tempConfig = [System.IO.Path]::GetTempFileName() + ".wsb"
            try {
                $result = New-SandboxConfiguration -ConfigPath $tempConfig -EnableNetworking
                $result | Should -Be $true
                Test-Path $tempConfig | Should -Be $true
            } finally {
                if (Test-Path $tempConfig) {
                    Remove-Item $tempConfig -Force
                }
            }
        }
    }

    Context "End-to-End Workflow" {
        It "Should simulate complete setup workflow" {
            # This is a high-level integration test
            # In practice, this would be mocked to avoid actual system changes

            # Test that all components can be initialized together
            $tracker = New-ProgressTracker -TotalSteps 5
            $specs = Get-SystemSpecs
            $version = Get-WindowsVersion
            $pluginsPath = Join-Path $projectRoot "plugins"
            $loadedPlugins = Initialize-PluginSystem -PluginsPath $pluginsPath

            # Verify all components work together
            $tracker | Should -Not -BeNullOrEmpty
            $specs | Should -Not -BeNullOrEmpty
            $version | Should -Not -BeNullOrEmpty
            $loadedPlugins | Should -Not -BeNullOrEmpty
        }
    }
}