# Fonction pour réparer les héritages cassés
Function Set-Inheritance {
 
[cmdletbinding(SupportsShouldProcess)]
 
Param(
[Parameter(Position=0,Mandatory,HelpMessage="Enter the file or folder path",
ValueFromPipeline=$True,ValueFromPipelineByPropertyName)]
[ValidateNotNullOrEmpty()]
[Alias("PSPath")]
[string]$Path,
[switch]$NoInherit,
[switch]$NoPreserve,
[switch]$Passthru
)
 
BEGIN {
    
    Write-Verbose  "Starting $($MyInvocation.Mycommand)"     
 
} #begin
 
PROCESS {
    Try {
        $fitem = Get-Item -path $(Convert-Path $Path) -ErrorAction Stop  
    }
    Catch {
        Write-Warning "Failed to get $path"
        Write-Warning $_.exception.message
        #bail out
        Return
    }
    if ($fitem) {
    Write-Verbose ("Resetting inheritance on {0}" -f $fitem.fullname)
    $aclProperties = Get-Acl $fItem
 
    Write-Verbose ($aclProperties | Select * | out-string)
    	
    if ($noinherit) {
        Write-Verbose "Setting inheritance to NoInherit"
    	if ($nopreserve) {
     #remove inherited access rules  
            Write-Verbose "Removing existing rules"          
     $aclProperties.SetAccessRuleProtection($true,$false)
     }
     else {
     #preserve inherited access rules
     $aclProperties.SetAccessRuleProtection($true,$true)
     }
    }
    else {
     #the second parameter is required but actually ignored
        #in this scenario
     $aclProperties.SetAccessRuleProtection($false,$false)
    }
    Write-Verbose "Setting the new ACL"
    #hashtable of parameters to splat to Set-ACL
    $setParams = @{
        Path = $fitem
        AclObject = $aclProperties
        Passthru = $Passthru
    }
    
    Set-Acl @setparams
    } #if $fitem
 
} #process
 
END {
 
    Write-Verbose  "Ending $($MyInvocation.Mycommand)"     
 
} #end
 
} #end function

# Fichier de log dans F:\Scripts\Share\
Start-Transcript -Path F:\Scripts\Share\Heritage_TraitementRepertoiresRacinesv1.log -Append

# Scan des répertoires racines
$path = "P:\Partages\"
$dir = Get-ChildItem -Attributes Directory -Path $path
$count = 0
foreach ($d in $dir)
{
    if ($d.Name -like "g*")
    {
        Write-host $d.Name -ForegroundColor Green
        #$acl = Get-Acl -Path "F:\Scripts\$d"
        #$acl.access.IdentityReference

        # Récupération des acls non hérités et de l'acl du dossier
        $dossier_name = $path + $d
        write-host $dossier_name
        $aclaccess = Get-Acl -Path $dossier_name | Select-Object -ExpandProperty Access | Where-Object { -Not $_.IsInherited }
        $aclfolder = Get-Acl -Path $dossier_name

        if ($aclfolder.AreAccessRulesProtected -eq $true)
        {
            Write-host $aclaccess.count -ForegroundColor Red
            $aclfolder
            $aclfolder.Access
            $count ++
            $aclfolder.SetAccessRuleProtection($False,$True)
            $aclfolder | Set-Acl -Path $dossier_name
        }
    }
}
write-host "Nb de dossiers sans permissions : $count"

Stop-Transcript

<#
$Path = "H:\Reseaux"
$aclfolder = 	Get-Acl -Path $Path
$aclfolder.SetAccessRuleProtection($False,$True)
$aclfolder | Set-Acl -Path $Path

$acl = get-acl -path "F:\Temp"
$perm = 'Everyone', 'Delete', 'None', 'None', 'Deny'
$rule = New-Object -TypeName System.Security.AccessControl.FileSystemAccessRule -ArgumentList $perm
$acl.SetAccessRule($rule)
$acl | Set-Acl -Path "F:\Temp"#>