$path = "C:\HAL\Powershell\Share\test\Share3"
$acl = get-acl -LiteralPath $path
$access = $acl.Access
#$access | select IdentityReference,FileSystemRights,IsInherited

$accessUnique = $access | ?{$_.IsInherited -eq "False"}
$accessInherited = $access | ?{$_.IsInherited -eq "True"}

write-host "Access Unique"
$accessUnique | select IdentityReference,FileSystemRights,IsInherited
write-host "Access Inherited"
$accessInherited | select IdentityReference,FileSystemRights,IsInherited
