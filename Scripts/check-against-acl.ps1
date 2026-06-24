# fill in
$Path = "Drive:\path\to\folder"
$User = "domain\mama"

$acl = Get-Acl $Path

$acl.Access |
Where-Object {
    $_.IdentityReference -eq $User -or
    # fill in 
    $_.IdentityReference -eq "domain\Domain Users" -or
    $_.IdentityReference -eq "BUILTIN\Users" -or
    $_.IdentityReference -eq "Everyone" -or
    $_.IdentityReference -eq "NT AUTHORITY\Authenticated Users"
} |
Format-Table IdentityReference, FileSystemRights, AccessControlType, IsInherited, InheritanceFlags, PropagationFlags -Auto
