$userinput = Read-Host "Enter the directory path or drive letter (i.e. C:) " 
$directories = Get-ChildItem -Path $userinput -Recurse -Directory | Select-Object -ExpandProperty FullName

$outputCSV = Read-Host "Enter the path to which the CSV will be exported "


$output = @() 
$number = 1


$dirs = $directories | ForEach-Object {
    $totalSize = (Get-ChildItem -File -Recurse $_ | Measure-Object -Property Length -Sum).Sum /1024 /1024 /1024

    $dataObject = [PSCustomObject]@{
        FilePath = $_
        Size = $totalSize.ToString("F4") 
    }

    $output+= $dataObject
    Write-Host $number
    $number++ 
}

$output | Export-CSV $outputCSV

Write-Host ""
Write-Host "Size will be diplayed in GB. Check the CSV file. " 
Write-Host "" 
Read-Host "Press Enter to Quit..."