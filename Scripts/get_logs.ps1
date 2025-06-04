# Define the date to filter logs after
$date = Get-Date "2025-06-03"

$system = Get-EventLog -LogName System -After $date 
$application = Get-EventLog -LogName Application -After $date
$security = Get-EventLog -LogName Security -After $date 

$systemLogs = "C:\Windows\SystemTemp\ApplicationLog$(date).csv"
$applicationLogs = "C:\Windows\SystemTemp\SystemLog$(date).csv"
$securityLogs = "C:\Windows\SystemTemp\SystemLog$(date).csv"


# Define output file paths using the date string for filenames
$dateString = $date.ToString("yyyy-MM-dd")
$systemLogs = "C:\Windows\SystemTemp\SystemLog_$dateString.csv"
$applicationLogs = "C:\Windows\SystemTemp\ApplicationLog_$dateString.csv"
$securityLogs = "C:\Windows\SystemTemp\SecurityLog_$dateString.csv"

$system | export-csv -Path $systemLogs
$application | export-csv -Path $applicationLogs
$security | export-csv -Path $securityLogs 


# Define the log channels
$logChannels = @(
    'Microsoft-Windows-RemoteDesktopServices-RdpCoreTS/Operational',
    'Microsoft-Windows-RemoteDesktopServices-SessionServices/Operational',
    'Microsoft-Windows-TerminalServices-RemoteConnectionManager/Operational',
    'Microsoft-Windows-TerminalServices-LocalSessionManager/Operational',
    'Microsoft-Windows-TerminalServices-ServerUSBDevices/Admin'
)

# save the logs
foreach ($logChannel in $logChannels) { 
    Write-Host "`n----- Logs from $logChannel -----"
    try {
        $logEvents = Get-WinEvent -FilterHashtable @{LogName=$logChannel; StartTime="2025-06-01"} -ErrorAction Stop
        $logEvents | Select-Object TimeCreated, Id, LevelDisplayName, Message | Format-List
        $logChannelClean = $logChannel-replace '[\\/]', ''
        $logEvents | export-csv -Path "C:\Windows\SystemTemp\$logChannelClean_$dateString.csv"
    } catch {
        Write-Warning "Failed to query ${logChannel}: $_"
    }
}
