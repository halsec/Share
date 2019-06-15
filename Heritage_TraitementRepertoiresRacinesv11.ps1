#$verbosePreference="Continue"

Function supprDoublonsUnique
{
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
            #$path = "C:\HAL\Powershell\Share\test\Share3"
            Write-Verbose  "PATH $path"
            $folderitem = Get-Item -LiteralPath $(Convert-Path $Path) -ErrorAction Stop
        }
        Catch {
            Write-Warning "Failed to get $path"
            Write-Warning $_.exception.message
            #bail out
            Return
        }
    $acl = get-acl $folderitem
    $access = $acl.Access
    #$access | select IdentityReference,FileSystemRights,IsInherited
    $accessInherited = $access | ?{ $_.IsInherited -eq $true}
    #$accessInherited | ft IdentityReference,FileSystemRights,IsInherited
    Write-Output "---------------------------------------------------------" -ForegroundColor yellow

    $accessUnique = $access | ?{$_.IsInherited -eq $false}
    #$accessUnique | ft IdentityReference,FileSystemRights,IsInherited

    $accessToRemove = Compare-Object -ReferenceObject $accessInherited -DifferenceObject $accessUnique  -Property IdentityReference,FileSystemRights -IncludeEqual
    #$accessToRemove | ?{$_.SideIndicator -eq "=="}

    write-output "------------------ UNIQUE ---------------------------------------" -ForegroundColor yellow
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

}#process
 
 END {
 
        Write-Verbose  "Ending $($MyInvocation.Mycommand)"     
 
    } #end
 
} #end function

# Fonction pour r�parer les h�ritages cass�s
Function Set-Inheritance
{
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
            Write-Verbose  "PATH $path"
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
                    Write-Verbose ($aclProperties | Select-Object * | out-string)                
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
} #end function Set-Inheritance

# Fichier de log dans F:\Scripts\Share\
#Start-Transcript -Path F:\Scripts\Share\Heritage_TraitementRepertoiresRacinesv1.log -Append
Start-Transcript -Path C:\HAL\Powershell\Share\log\Heritage_Traitement.log -Append

# Scan des r�pertoires racines
$path = "C:\HAL\Powershell\Share\test"
$dir = Get-ChildItem -Attributes Directory -Path $path -Recurse
$count = 0

foreach ($d in $dir)
{
    $chemin = $d.FullName
    write-output $chemin -ForegroundColor Green
    $acl = get-acl -LiteralPath $chemin
    $accessavant = $acl.Access
    write-output ("Protected {0}" -f $acl.AreAccessRulesProtected)
    #get-acl -LiteralPath $chemin -Audit | ForEach-Object { $_.Audit.Count }
     
    Set-Inheritance $chemin -NoPreserve
    $acl = get-acl -LiteralPath $chemin
    $accessapres = $acl.Access
    Compare-Object -ReferenceObject $accessavant -DifferenceObject $accessapres --Property IdentityReference,FileSystemRights
    $count ++
}
<#
    # R�cup�ration des acls non h�rit�s et de l'acl du dossier
    $dossier_name = $path + $d
    write-output $dossier_name
    $aclaccess = Get-Acl -Path $dossier_name | Select-Object -ExpandProperty Access | Where-Object { -Not $_.IsInherited }
    $aclfolder = Get-Acl -Path $dossier_name

    if ($aclfolder.AreAccessRulesProtected -eq $true)
    {
        write-output $aclaccess.count -ForegroundColor Red
        $aclfolder
        $aclfolder.Access
        $count ++
        $aclfolder.SetAccessRuleProtection($False,$True)
        $aclfolder | Set-Acl -Path $dossier_name
    }
}#>
write-output "Nb de dossiers sans permissions : $count"

Stop-Transcript

<#
#Backup restore
$acl = get-acl -Path C:\HAL\Powershell\Share\test\Share2
$sddl= $acl.sddl

$acl = get-acl -Path C:\HAL\Powershell\Share\test\Share2
$acl.SetSecurityDescriptorSddlForm($sddl)
set-acl -Path C:\HAL\Powershell\Share\test\Share2 -AclObject $acl

#>