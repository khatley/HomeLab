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

$RemoteCred = Get-Credential -Message "Enter credentials for the remote Hyper-V server"

foreach ($Config in $VMConfigs){
    $ComputerName = $Config.ComputerName
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
    New-VHD -ComputerName $ComputerName -Path $VHDPath -SizeBytes $VHDSizeBytes -Credential $RemoteCred

    # --- Create Virtual Machine ---
    New-VM -Name $VMName -ComputerName $ComputerName -MemoryStartupBytes $MemoryStartupBytes -Generation $Generation -Credential $RemoteCred

    # --- Configure Processor ---
    Set-VMProcessor -VMName $VMName -ComputerName $ComputerName -Count $ProcessorCount -Credential $RemoteCred

    # --- Connect Network Adapter to Virtual Switch ---
    Connect-VMNetworkAdapter -VMName $VMName -ComputerName $ComputerName -Name "Network Adapter" -SwitchName $SwitchName -Credential $RemoteCred

    # --- Add DVD Drive and Mount ISO ---
    Add-VMDvdDrive -VMName $VMName -ComputerName $ComputerName -Path $ISOPath -Credential $RemoteCred

    # --- Add Existing Hard Disk ---
    Add-VMHardDiskDrive -VMName $VMName -ComputerName $ComputerName -Path $VHDPath -Credential $RemoteCred

    # --- Set Boot Order and Disable SecureBoot ---
    $firmware = Get-VMFirmware -VMName $VMName -ComputerName $ComputerName -Credential $RemoteCred
    $network = $firmware.bootorder[0]
    $dvd = $firmware.bootorder[1]
    $vhd = $firmware.bootorder[2]

    Set-VMFirmware -VMName $VMName -ComputerName $ComputerName -FirstBootDevice $dvd -Credential $RemoteCred
    Set-VMFirmware -VMName $VMName -ComputerName $ComputerName -EnableSecureBoot Off -Credential $RemoteCred

    # --- Start the Virtual Machine ---
    Write-Host "Starting virtual machine '$VMName'..."
    Start-VM -Name $VMName -ComputerName $ComputerName -Credential $RemoteCred
    # --- Set permant boot order ---
    Set-VMFirmware -VMName $VMName -ComputerName $ComputerName -BootOrder $vhd, $dvd, $network -Credential $RemoteCred
    Write-Host "Virtual machine '$VMName' created and started. The OS installation should begin."
}