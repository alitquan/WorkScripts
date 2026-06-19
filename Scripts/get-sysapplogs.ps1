param(
    [int]$Days = 2
)

$StartTime = (Get-Date).AddDays(-$Days)

Get-WinEvent -FilterHashtable @{
    LogName   = @('System','Application')
    StartTime = $StartTime
    Level     = 1,2,3   # 1=Critical, 2=Error, 3=Warning
} | Select-Object TimeCreated, LogName, ProviderName, Id, LevelDisplayName, Message |
    Sort-Object TimeCreated -Descending
