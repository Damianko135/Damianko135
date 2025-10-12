# HardwareDetector.psm1
# Module for detecting system hardware specifications

function Get-SystemSpecs {
    $systemInfo = Get-WmiObject -Class Win32_ComputerSystem
    $processor = Get-WmiObject -Class Win32_Processor | Select-Object -First 1
    $memory = Get-WmiObject -Class Win32_PhysicalMemory | Measure-Object -Property Capacity -Sum
    $disk = Get-WmiObject -Class Win32_LogicalDisk -Filter "DeviceID='C:'"

    $specs = @{
        Manufacturer = $systemInfo.Manufacturer
        Model = $systemInfo.Model
        TotalMemoryGB = [math]::Round($memory.Sum / 1GB, 2)
        ProcessorName = $processor.Name
        ProcessorCores = $processor.NumberOfCores
        ProcessorLogicalProcessors = $processor.NumberOfLogicalProcessors
        SystemType = $systemInfo.SystemType
        TotalDiskSpaceGB = [math]::Round($disk.Size / 1GB, 2)
        FreeDiskSpaceGB = [math]::Round($disk.FreeSpace / 1GB, 2)
    }

    return $specs
}

function Test-IsLaptop {
    $chassis = Get-WmiObject -Class Win32_SystemEnclosure | Select-Object -First 1
    # Chassis types: 8=Portable, 9=Laptop, 10=Notebook, 14=Sub Notebook
    $laptopTypes = @(8, 9, 10, 14)
    return $laptopTypes -contains $chassis.ChassisTypes[0]
}

function Get-WindowsVersion {
    $os = Get-WmiObject -Class Win32_OperatingSystem
    return @{
        Caption = $os.Caption
        Version = $os.Version
        BuildNumber = $os.BuildNumber
        IsWindows11 = [int]$os.BuildNumber -ge 22000
    }
}

function Get-GPUInfo {
    $gpus = Get-WmiObject -Class Win32_VideoController
    return $gpus | ForEach-Object {
        @{
            Name = $_.Name
            DriverVersion = $_.DriverVersion
            VideoProcessor = $_.VideoProcessor
            AdapterRAM = [math]::Round($_.AdapterRAM / 1MB, 2)
        }
    }
}

# Export functions
Export-ModuleMember -Function Get-SystemSpecs, Test-IsLaptop, Get-WindowsVersion, Get-GPUInfo