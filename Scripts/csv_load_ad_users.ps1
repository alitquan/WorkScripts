Import-Module ActiveDirectory

#creating window for the import
[System.Reflection.Assembly]::LoadWithPartialName("System.window.forms") | Out-Null
$prompt = New-Object System.Windows.Forms.OpenFileDialog
$prompt.InitialDirectory = "C:\"

# filtering for csv files
$prompt.Filter = "CSV (*.csv) | *.csv"
$prompt.ShowDialog() | Out-Null
$csv_path = $prompt.FileName
echo $csv_path

#importing the csv
$csv = Import-CSV -LiteralPath "$csv_path"

ForEach($user in $csv) {
    $shownName       = "$($user.'Computer')"
    $userName        = "$($user.'Login Name')"
    $permissions     = "$($user.'Permissions')"
    $dept            = "$($user.'Department')"

    # $ou refers to the OU in the excel file
    # need to enter the OUs in reverse order. specify dc in normal order
    $existingOU      = "OU=redacted,dc=redacted,dc=redacted,dc=com"
    $ou              = "$($user.'Organizational Unit')"
    $path            = "OU=$ou,OU=redacted,dc=redacted,dc=redacted,dc=com"

    $notes           = "$($user.'Notes')"
    $defaultPassword = ConvertTo-SecureString -String "redacted" -AsPlainText -Force
   

    # debugging
    echo ""
    echo $shownName
    echo $userName
    echo $dept
    echo $permissions
    echo $path
    
    


    if ($ou -ne "N/A") {

        # creates OU if it does not exist
        try {
            Get-ADOrganizationalUnit -Identity $ou | Out-Null
            Write-Verbose "OU '$ou' already exists."
        }
        catch [Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException] {
            Write-Verbose "Creating new OU '$ou'"
            New-ADOrganizationalUnit -Name $ou -Path $existingOU 
        }

        echo "Is in a valid OU -- creating user"
        New-ADUser -Name $userName `
                   -GivenName $shownName `
                   -Department $dept `
                   -Path $path `
                   -ChangePasswordAtLogon $true `
                   -AccountPassword $defaultPassword `
                   -Enabled $true
    }
    else {
        echo "No applicable OU"
    }

  
}

