Write-Host "Deleting Previous TestVM instances"

Stop-VM -Name "TestVM1" -TurnOff
Remove-VM -Name "TestVM1" -Force
Remove-Item C:\Hyper-V\VMs\TestVM1.vhdx

Stop-VM -Name "TestVM2" -TurnOff
Remove-VM -Name "TestVM2" -Force
Remove-Item C:\Hyper-V\VMs\TestVM2.vhdx

Stop-VM -Name "TestVM3" -TurnOff
Remove-VM -Name "TestVM3" -Force
Remove-Item C:\Hyper-V\VMs\TestVM3.vhdx

Write-Host "TestVMs have been deleted"