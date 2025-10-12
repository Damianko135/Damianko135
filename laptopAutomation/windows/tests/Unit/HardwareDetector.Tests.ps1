Describe "HardwareDetector Module Tests" {
    BeforeAll {
        $modulePath = Join-Path $PSScriptRoot "..\..\modules\HardwareDetector.psm1"
        Import-Module $modulePath -Force

        # Mock WMI/CIM calls
        Mock Get-CimInstance {
            [PSCustomObject]@{
                Manufacturer = "TestManufacturer"
                Model = "TestModel"
                TotalPhysicalMemory = 17179869184  # 16GB in bytes
                NumberOfCores = 8
                Name = "Test Processor"
            }
        } -ParameterFilter { $ClassName -eq "Win32_ComputerSystem" }

        Mock Get-CimInstance {
            [PSCustomObject]@{
                Caption = "Microsoft Windows 11 Pro"
                Version = "10.0.22000"
                BuildNumber = "22000"
            }
        } -ParameterFilter { $ClassName -eq "Win32_OperatingSystem" }
    }

    AfterAll {
        Remove-Module HardwareDetector -ErrorAction SilentlyContinue
    }

    Context "Module Loading" {
        It "Should import HardwareDetector module successfully" {
            $module = Get-Module HardwareDetector
            $module | Should -Not -BeNullOrEmpty
            $module.Name | Should -Be "HardwareDetector"
        }

        It "Should export required functions" {
            $exportedFunctions = (Get-Module HardwareDetector).ExportedFunctions.Keys
            $exportedFunctions | Should -Contain "Get-SystemSpecs"
            $exportedFunctions | Should -Contain "Get-WindowsVersion"
        }
    }

    Context "System Specifications Detection" {
        It "Should detect system manufacturer and model" {
            $specs = Get-SystemSpecs
            $specs.Manufacturer | Should -Be "TestManufacturer"
            $specs.Model | Should -Be "TestModel"
        }

        It "Should calculate memory in GB correctly" {
            $specs = Get-SystemSpecs
            $specs.TotalMemoryGB | Should -Be 16
        }

        It "Should detect processor information" {
            $specs = Get-SystemSpecs
            $specs.ProcessorName | Should -Be "Test Processor"
            $specs.ProcessorCores | Should -Be 8
        }

        It "Should return all required properties" {
            $specs = Get-SystemSpecs
            $specs.PSObject.Properties.Name | Should -Contain "Manufacturer"
            $specs.PSObject.Properties.Name | Should -Contain "Model"
            $specs.PSObject.Properties.Name | Should -Contain "TotalMemoryGB"
            $specs.PSObject.Properties.Name | Should -Contain "ProcessorName"
            $specs.PSObject.Properties.Name | Should -Contain "ProcessorCores"
        }
    }

    Context "Windows Version Detection" {
        It "Should detect Windows version information" {
            $version = Get-WindowsVersion
            $version.Caption | Should -Be "Microsoft Windows 11 Pro"
            $version.Version | Should -Be "10.0.22000"
            $version.BuildNumber | Should -Be "22000"
        }

        It "Should correctly identify Windows 11" {
            $version = Get-WindowsVersion
            $version.IsWindows11 | Should -Be $true
        }

        It "Should identify Windows 10 correctly" {
            Mock Get-CimInstance {
                [PSCustomObject]@{
                    Caption = "Microsoft Windows 10 Pro"
                    Version = "10.0.19045"
                    BuildNumber = "19045"
                }
            } -ParameterFilter { $ClassName -eq "Win32_OperatingSystem" }

            $version = Get-WindowsVersion
            $version.IsWindows11 | Should -Be $false
        }

        It "Should return all required properties" {
            $version = Get-WindowsVersion
            $version.PSObject.Properties.Name | Should -Contain "Caption"
            $version.PSObject.Properties.Name | Should -Contain "Version"
            $version.PSObject.Properties.Name | Should -Contain "BuildNumber"
            $version.PSObject.Properties.Name | Should -Contain "IsWindows11"
        }
    }

    Context "Error Handling" {
        It "Should handle WMI query failures gracefully" {
            Mock Get-CimInstance { throw "WMI query failed" }

            { Get-SystemSpecs } | Should -Throw
            { Get-WindowsVersion } | Should -Throw
        }

        It "Should handle missing properties" {
            Mock Get-CimInstance {
                [PSCustomObject]@{
                    # Missing some properties
                    Manufacturer = "TestManufacturer"
                }
            } -ParameterFilter { $ClassName -eq "Win32_ComputerSystem" }

            $specs = Get-SystemSpecs
            $specs.Manufacturer | Should -Be "TestManufacturer"
            # Other properties should handle missing values
        }
    }

    Context "Performance" {
        It "Should execute within reasonable time" {
            $executionTime = Measure-Command { Get-SystemSpecs; Get-WindowsVersion }
            $executionTime.TotalMilliseconds | Should -BeLessThan 5000  # Less than 5 seconds
        }
    }
}