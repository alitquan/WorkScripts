# need to run this on Task Scheduler on the server 

# Collecting CPU and Memory Usage
$cpu = Get-Counter '\Processor(_Total)\% Processor Time'
$memory = Get-Counter '\Memory\Available MBytes'

# Get the computer name 
$computerName = $ENV:COMPUTERNAME
  
# Custom object
$data = [PSCustomObject]@{
    TimeStamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    CPU = $cpu.CounterSamples[0].CookedValue
    Memory = $memory.CounterSamples[0].CookedValue
}

# Export to CSV
$filePath = "C:\${computerName}_cpu_memory_usage.csv"
$data | Export-Csv -Path $filePath -Append -NoTypeInformation
