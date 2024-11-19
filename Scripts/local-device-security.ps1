# password policies 
net accounts /maxpwage:90
net accounts /minpwlen:10 
net accounts /uniquepw:5 
net accounts /minpwage:0 

# creating storage partition 
Resize-Partition -DriveLetter C -Size ((Get-Partition -DriveLetter C).Size - 5GB)
New-Partition -DiskNumber 0 -Size 5GB -DriveLetter E
Format-Volume -DriveLetter E -FileSystem NTFS -NewFileSystemLabel "Storage"

# disable USB 
Set-ItemProperty -Path "HKLM:\SYSTEM\ControlSet001\Services\USBSTOR" -Name "Start" -Value 4
