<#
.SYNOPSIS
    Creates a new Hyper-V virtual machine with a specified OS.

.DESCRIPTION
    This script creates a new Hyper-V virtual machine with the specified name,
    memory, CPU, network, and installs the OS from the provided ISO path.

.PARAMETER VMName
    The name of the virtual machine to create.

.PARAMETER ProcessorCount
    The total number of processors available to the VM.

.PARAMETER MemoryStartupBytes
    The initial memory allocation for the virtual machine (e.g., 4GB = 4GB).

.PARAMETER VHDPath
    The full path where the new virtual hard disk will be created.

.PARAMETER VHDSizeBytes
    The size of the new virtual hard disk in bytes (e.g., 50GB = 50GB).

.PARAMETER ISOPath
    The full path to the operating system ISO file.

.PARAMETER SwitchName
    The name of the virtual switch to connect the VM to.

.EXAMPLE
    .\Create-VM.ps1 .\VM-Alpine-Parameters.json
    TEST CHANGE TO CONFIRM GIT IS WORKING
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [string]$JSONPath
)

if(Test-Path -Path $JSONPath){
    $VMConfigs = Get-Content -Path $JSONPath -Raw | ConvertFrom-Json
}else{
    Write-Host "File Path Invalid. Please verify"
    exit 1
}

foreach ($Config in $VMConfigs){
    $VMName = $Config.VMName
    $ProcessorCount = [int]$Config.ProcessorCount
    $MemoryStartupBytes = [int]$Config.MemoryStartupBytes * 1GB
    $VHDPath = $Config.VHDPath
    $VHDSizeBytes = [int]$Config.VHDSizeBytes * 1GB
    $ISOPath = $Config.ISOPath
    $SwitchName = $Config.SwitchName

    # --- Configuration ---
    $Generation = 2 # 1 or 2 for UEFI support if the OS and host support it

    # --- Create Virtual Hard Disk ---
    New-VHD -Path $VHDPath -SizeBytes $VHDSizeBytes

    # --- Create Virtual Machine ---
    New-VM -Name $VMName -MemoryStartupBytes $MemoryStartupBytes -Generation $Generation

    # --- Configure Processor ---
    Set-VMProcessor -VMName $VMName -Count $ProcessorCount

    # --- Connect Network Adapter to Virtual Switch ---
    Connect-VMNetworkAdapter -VMName $VMName -Name "Network Adapter" -SwitchName $SwitchName

    # --- Add DVD Drive and Mount ISO ---
    Add-VMDvdDrive -VMName $VMName -Path $ISOPath

    # --- Add Existing Hard Disk ---
    Add-VMHardDiskDrive -VMName $VMName -Path $VHDPath

    # --- Set Boot Order and Disable SecureBoot ---
    $firmware = Get-VMFirmware -VMName $VMName
    $network = $firmware.bootorder[0]
    $dvd = $firmware.bootorder[1]
    $vhd = $firmware.bootorder[2]

    Set-VMFirmware -VMName $VMName -FirstBootDevice $dvd
    Set-VMFirmware -VMName $VMName -EnableSecureBoot Off

    # --- Start the Virtual Machine ---
    Write-Host "Starting virtual machine '$VMName'..."
    Start-VM -Name $VMName

    # --- Set permant boot order ---
    Set-VMFirmware -VMName $VMName -BootOrder $vhd, $dvd, $network
    Write-Host "Virtual machine '$VMName' created and started. The OS installation should begin."
}