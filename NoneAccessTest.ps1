$path = "C:\HAL\Powershell\Share\test\Share3"
$acl = get-acl -LiteralPath $path
$access = $acl.Access
#$access | select IdentityReference,FileSystemRights,IsInherited
$accessInherited = $access | ?{ $_.IsInherited -eq $true}
$accessInherited | ft IdentityReference,FileSystemRights,IsInherited
Write-Host "---------------------------------------------------------" -ForegroundColor yellow

$accessUnique = $access | ?{$_.IsInherited -eq $false}
$accessUnique | ft IdentityReference,FileSystemRights,IsInherited

$accessToRemove = Compare-Object -ReferenceObject $accessInherited -DifferenceObject $accessUnique -Property IdentityReference,FileSystemRights -IncludeEqual
$accessToRemove | ?{$_.SideIndicator -eq "=="}

Write-Host "------------------ UNIQUE ---------------------------------------" -ForegroundColor yellow
#$access | sort | select -Unique

#Suppression des permissions en double et non héritées
[System.Collections.ArrayList]$rules = @()
ForEach ($accessEnTrop in ($accessToRemove | ?{$_.SideIndicator -eq "=="}))
{
    #("Identity {0}" -f $accessEnTrop.IdentityReference)
    $rules += $acl.access | Where-Object { 
        (-not $_.IsInherited) -and 
        $_.IdentityReference -eq $accessEnTrop.IdentityReference
    }
}
ForEach($rule in $rules) {
    $acl.RemoveAccessRule($rule) | Out-Null
    $rule
}
Set-ACL -Path $path -AclObject $acl

