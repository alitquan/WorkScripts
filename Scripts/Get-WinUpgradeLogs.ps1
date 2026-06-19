function Get-WinUpgradeLogs {
    [CmdletBinding()]
    param(
        [switch]$Compress,
        [switch]$NoSearch
    )

    $Timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $Out = Join-Path $env:USERPROFILE "Desktop\UpgradeLogs_$Timestamp"

    $Paths = @(
        'C:\$WINDOWS.~BT\Sources\Panther',
        'C:\$WINDOWS.~BT\Sources\Rollback',
        'C:\Windows\Panther',
        'C:\Windows\Panther\NewOS\Panther',
        'C:\Windows\Logs\CBS',
        'C:\Windows\Logs\DISM'
    )

    $LogPatterns = @(
        'setupact.log',
        'setuperr.log',
        'BlueBox.log',
        'setupapi.dev.log',
        'setupapi.app.log',
        'CompatData*.xml',
        '*.etl',
        '*.evtx',
        'CBS.log',
        'dism.log'
    )

    $SearchTerms = @(
        '0xC1900101',
        '0x40021',
        'SYSPREP',
        'RESPECIALIZE',
        'ROLLBACK',
        'MOSETUP',
        'Error',
        'Failure',
        'oem\d+\.inf'
    ) -join '|'

    function ConvertTo-SafePathName {
        param(
            [Parameter(Mandatory)]
            [string]$Path
        )

        ($Path -replace '[:\\$]', '_').Trim('_')
    }

    function Copy-UpgradeLogPath {
        param(
            [Parameter(Mandatory)]
            [string]$SourcePath,

            [Parameter(Mandatory)]
            [string]$DestinationRoot
        )

        if (-not (Test-Path -LiteralPath $SourcePath)) {
            Write-Verbose "Path not found: $SourcePath"
            return
        }

        $SafeName = ConvertTo-SafePathName -Path $SourcePath
        $Destination = Join-Path $DestinationRoot $SafeName

        New-Item -ItemType Directory -Path $Destination -Force | Out-Null

        Copy-Item `
            -LiteralPath $SourcePath `
            -Destination $Destination `
            -Recurse `
            -Force `
            -ErrorAction SilentlyContinue
    }

    function Get-UpgradeLogFiles {
        param(
            [Parameter(Mandatory)]
            [string]$RootPath
        )

        Get-ChildItem -LiteralPath $RootPath  -Recurse -File -Include $LogPatterns -ErrorAction SilentlyContinue
    }

    function Write-UpgradeLogManifest {
        param(
            [Parameter(Mandatory)]
            [string]$RootPath
        )

        $ManifestPath = Join-Path $RootPath 'manifest.txt'

        $Manifest = Get-UpgradeLogFiles -RootPath $RootPath |
            Select-Object FullName, Length, LastWriteTime |
            Sort-Object LastWriteTime -Descending

        $Manifest |
            Format-Table -AutoSize |
            Out-String -Width 300 |
            Set-Content -Path $ManifestPath -Encoding UTF8

        $ManifestPath
    }

    function Search-UpgradeLogs {
        param(
            [Parameter(Mandatory)]
            [string]$RootPath,

            [switch]$WriteToFile
        )

        $Results = Get-UpgradeLogFiles -RootPath $RootPath |
            ForEach-Object {
                Se1ect-String -LiteralPath $_.FullName -Pattern $SearchTerms -Context 3, 3 -ErrorAction SilentlyContinue
                | Select-Object -First 80
            }

        if ($WriteToFile) {
            $SearchOutput = Join-Path $RootPath 'quick_search_results.txt'

            if ($Results) {
                $Results |
                    Out-String -Width 300 |
                    Set-Content -Path $SearchOutput -Encoding UTF8
            }
            else {
                'No matching terms found.' |
                    Set-Content -Path $SearchOutput -Encoding UTF8
            }

            return $SearchOutput
        }

        if ($Results) {
            $Results
        }
        else {
            Write-Host "No matching terms found."
        }
    }

    New-Item -ItemType Directory -Path $Out -Force | Out-Null

    foreach ($Path in $Paths) {
        Copy-UpgradeLogPath -SourcePath $Path -DestinationRoot $Out
    }

    $ManifestPath = Write-UpgradeLogManifest -RootPath $Out

    Write-Host "Created log bundle folder:"
    Write-Host $Out
    Write-Host ""
    Write-Host "Manifest:"
    Write-Host $ManifestPath
    Write-Host ""

    if (-not $NoSearch) {
        if ($Compress) {
            $SearchOutput = Search-UpgradeLogs -RootPath $Out -WriteToFile

            Write-Host "Quick search results:"
            Write-Host $SearchOutput
            Write-Host ""
        }
        else {
            Write-Host "Quick search results:"
            Search-UpgradeLogs -RootPath $Out
            Write-Host ""
        }
    }

    if ($Compress) {
        $ZipPath = "$Out.zip"

        Compress-Archive `
            -Path (Join-Path $Out '*') `
            -DestinationPath $ZipPath `
            -Force

        Write-Host "Created compressed archive:"
        Write-Host $ZipPath

        return $ZipPath
    }

    return $Out
}
