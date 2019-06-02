$path = "C:\HAL\Powershell\Share\test\Share3"
$acl = get-acl -LiteralPath $path
$access = $acl.Access
$access

