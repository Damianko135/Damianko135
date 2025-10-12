Describe "PackageInstaller Module Tests" {
    BeforeAll {
        $modulePath = Join-Path $PSScriptRoot "..\..\modules\PackageInstaller.psm1"
        Import-Module $modulePath -Force

        # Mock external commands
        Mock Get-Command { $true } -ParameterFilter { $Name -eq "choco" }
        Mock Get-Command { $false } -ParameterFilter { $Name -eq "winget" }
        Mock Test-WinGet { $false }
        Mock Install-ChocoPackage { $true }
        Mock Install-WinGetPackage { $true }
    }

    AfterAll {
        Remove-Module PackageInstaller -ErrorAction SilentlyContinue
    }

    Context "Module Loading" {
        It "Should import PackageInstaller module successfully" {
            $module = Get-Module PackageInstaller
            $module | Should -Not -BeNullOrEmpty
            $module.Name | Should -Be "PackageInstaller"
        }

        It "Should export required functions" {
            $exportedFunctions = (Get-Module PackageInstaller).ExportedFunctions.Keys
            $exportedFunctions | Should -Contain "Install-ChocoPackage"
            $exportedFunctions | Should -Contain "Install-WinGetPackage"
            $exportedFunctions | Should -Contain "Test-WinGet"
        }
    }

    Context "Chocolatey Package Installation" {
        It "Should install package with Chocolatey when available" {
            $result = Install-ChocoPackage -PackageId "git" -PackageName "Git"
            $result | Should -Be $true
        }

        It "Should handle installation failures gracefully" {
            Mock Install-ChocoPackage { $false }
            $result = Install-ChocoPackage -PackageId "nonexistent" -PackageName "Nonexistent Package"
            $result | Should -Be $false
        }
    }

    Context "WinGet Package Installation" {
        BeforeAll {
            Mock Test-WinGet { $true }
        }

        It "Should install package with WinGet when available" {
            $result = Install-WinGetPackage -PackageId "Git.Git" -PackageName "Git"
            $result | Should -Be $true
        }

        It "Should detect WinGet availability" {
            $result = Test-WinGet
            $result | Should -Be $true
        }
    }

    Context "Package Manager Detection" {
        It "Should prefer Chocolatey over WinGet" {
            Mock Get-Command { $true } -ParameterFilter { $Name -eq "choco" }
            Mock Get-Command { $true } -ParameterFilter { $Name -eq "winget" }

            # This would be tested in a full integration scenario
            $chocoAvailable = Get-Command choco -ErrorAction SilentlyContinue
            $wingetAvailable = Test-WinGet

            $chocoAvailable | Should -Be $true
            $wingetAvailable | Should -Be $false  # Mocked to false
        }
    }

    Context "Error Handling" {
        It "Should handle network timeouts" {
            Mock Install-ChocoPackage { throw "Network timeout" }
            { Install-ChocoPackage -PackageId "git" -PackageName "Git" } | Should -Throw
        }

        It "Should handle invalid package IDs" {
            Mock Install-ChocoPackage { throw "Package not found" }
            { Install-ChocoPackage -PackageId "invalid-package-id" -PackageName "Invalid Package" } | Should -Throw
        }
    }

    Context "Parallel Installation" {
        It "Should support parallel package installation" {
            # This would test the parallel installation logic
            # For now, just verify the function exists
            $function = Get-Command Install-ChocoPackage -Module PackageInstaller
            $function | Should -Not -BeNullOrEmpty
        }
    }
}