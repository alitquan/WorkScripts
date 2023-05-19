$ous = Get-ADOrganizationalUnit -Filter 'Name -like "*"' | select Name, DistinguishedName 
echo "testing" 
foreach($ou in $ous) {

   $arg1 = "$($ou.Name)"
   $arg2 = "$($ou.DistinguishedName)" 
   if ($arg1 -eq "IT") {
        continue 
   } 
   if ($arg1 -eq "Domain Controllers") {
        continue
   }
   if ($arg1 -eq "ouName1") {
        continue
   }
   if ($arg1 -ne "ouName2") {
        continue
   }


   echo $arg1
   $users = Get-ADUser -Filter * -SearchBase $arg2  -Properties ProfilePath, HomeDirectory, HomeDrive    



   $counter = 0

   
   foreach ($user in $users) {
        $userAttrs = $user | Select Name, SamAccountName, ProfilePath, HomeDirectory, HomeDrive
        echo $userAttrs
        echo $counter
        ++$counter

        $username    = $($userAttrs.SamAccountName)
        $profilePath = "\\serverName\Roaming_Profiles$\" + $username  
        $homePath   = "\\servername\Home_Folders$\{0}" -f $username 
        
        try {
            Set-ADUser $username  -ProfilePath $profilePath
            Set-ADUser $username   -HomeDirectory $homePath -HomeDrive H:
            $domain=((gwmi Win32_ComputerSystem).Domain).Split(".")[0]
            
            # adding permissions
            if (-not (Test-Path "$homePath")) {
                $acl = Get-Acl (New-Item -Path $homePath -ItemType Directory)
                $acl.SetAccessRuleProtection($false, $true)
                $ace = "$domain\$username","FullControl", "ContainerInherit,ObjectInherit","None","Allow"
                $objACE = New-Object System.Security.AccessControl.FileSystemAccessRule($ace)
                $acl.AddAccessRule($objACE)
                Set-ACL -Path "$homePath" -AclObject $acl

            }

        }
        catch {
            Write-Host "Error: ${$_.Exception.Message)}"
        }
    
   } 

   

}
