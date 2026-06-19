param(
    [int]$Days = 2
)

$StartTime = (Get-Date).AddDays(-$Days)

$RdpLogs = @(
    'Microsoft-Windows-TerminalServices-LocalSessionManager/Operational',
    'Microsoft-Windows-TerminalServices-RemoteConnectionManager/Operational',
    'Microsoft-Windows-RemoteDesktopServices-RdpCoreTS/Operational',
    'Microsoft-Windows-TerminalServices-ClientActiveXCore/Operational'
)

$Results = foreach ($Log in $RdpLogs) {
    Get-WinEvent -FilterHashtable @{
        LogName   = $Log
        StartTime = $StartTime
    } -ErrorAction SilentlyContinue |
        Select-Object TimeCreated, LogName, Id, LevelDisplayName, ProviderName, Message
}

$Results |
    Sort-Object TimeCreated -Descending |
    Export-Csv "$env:USERPROFILE\Desktop\RDP_Events_start__$startTime.csv" -NoTypeInformation
