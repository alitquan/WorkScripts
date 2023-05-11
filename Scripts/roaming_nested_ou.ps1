$ous = Get-ADOrganizationalUnit -Filter 'Name -like "*"' | select Name, DistinguishedName 
echo "testing" 
foreach($ou in $ous) {

   $arg1 = "$($ou.Name)"
   $arg2 = "$($ou.DistinguishedName)" 

   #some OUs will not feature roaming profiles
   if ($arg1 -eq "redacted") {
        continue 
   } 
   if ($arg1 -eq "Domain Controllers") {
        continue
   }
   if ($arg1 -eq "redacted") {
        continue
   }


   echo $arg1
   $users = Get-ADUser -Filter * -SearchBase $arg2  -Properties ProfilePath, HomeDirectory, HomeDrive    



   $counter = 0

   # path to profile storage
   $origProfilePath = "\\insert_path\Roaming_Profiles$\"

   # path to home folder storage
   $origLocalPath   = "\\insert_path\Roaming_Home$\" 
   
   foreach ($user in $users) {
        $userAttrs = $user | Select Name, SamAccountName, ProfilePath, HomeDirectory, HomeDrive
        echo $userAttrs
        echo $counter
        ++$counter

        $profilePath = $origProfilePath + $($userAttrs.SamAccountName)
        $localPath   = $origLocalPath + $($userAttrs.SamAccountName)
        
        Set-ADUser $($userAttrs.SamAccountName) -ProfilePath $profilePath -HomeDirectory $localPath -HomeDrive H
   } 

   

}