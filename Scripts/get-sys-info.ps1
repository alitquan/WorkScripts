$compInfo = get-computerinfo
$ipv4 = Test-Connection -ComputerName (hostname) -Count 1 | Select -ExpandProperty IPV4Address | Select -ExpandProperty IPAddressToString
$serial = Get-WMIObject -class win32_bios | Select -ExpandProperty SerialNumber
$model = $compInfo | select -ExpandProperty CsModel
$hdSpace = get-volume | where-object DriveLetter -eq 'C' | Select @{Name="GB";Expression={$_.size/1GB}} | Select -ExpandProperty GB
$ram = (systeminfo | Select-String 'Total Physical Memory:').ToString().Split(':')[1].Trim()
$cpu = Get-CimInstance -Class CIM_Processor | select -ExpandProperty Name


$retVal = "Hostname: " + (hostname),"`nIPv4: " + $ipv4, "`nSerial: " + $serial, "`nModel: "+ $model, "`nHD Space: " + $hdSpace, "GB`nRAM: " + $ram,"`nCPU: " + $cpu
write-output $retVal
$outputPath = "E:/Data/" + (hostname) + ".txt"
$retVal | Out-File -FilePath $outputPath
Start-Sleep -Seconds 5


<#
$driveLine = get-PSDrive | where-object Name -eq 'C'
>
