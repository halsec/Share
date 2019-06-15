#Récupération du répertoire où se trouve le script
function Get-Script-Directory
{
    $scriptInvocation = (Get-Variable MyInvocation -Scope 1).Value
    return Split-Path $scriptInvocation.MyCommand.Path
}

# Fonction pour générer un fichier de log
Function Out-Log { 
<# 
.Synopsis 
Manage log event send by script 
 
.Description  
Each time script send a log, this function append it to the journal array. 
As the journal contains objects, you can use convertto functions or out-gridview 
 
.Parameter Name 
The name of the entry 
 
.Parameter Msg 
The message associate with the entry 
 
.Parameter type 
The log type as String, it could be INFO, WARN, ERROR, COMMENT 
 
.EXEMPLE 
Out-Log -Name "Section1" -Msg "The function returned true" -type INFO 
#>    Param( 
    [parameter(Mandatory=$true)] 
    [String] $Name, 
    [parameter(Mandatory=$true)] 
    [String] $Msg, 
    [parameter(Mandatory=$true)] 
    [validateset("INFO", "WARN", "ERROR", "COMMENT")] 
    $Type 
    ) 
 
    # create log object 
    $log = [pscustomobject] @{Date=(get-date -UFormat %Y%m%d_%H%M%S); Type=$type ; Msg=$msg ; Name=$name} 
    $log | add-member -Name ToString -MemberType ScriptMethod -value {$this.date + ' : ' + $this.type +' : ' +$this.msg +' : ' + $this.name} -Force 
    # append it to the journal 
    [pscustomobject[]] $Script:journal += $log 
 
    # print to screen 
    switch ($type) { 
        'INFO' {Write-Host -ForegroundColor Green -Object $log} 
        'WARN' {Write-Host -ForegroundColor Yellow -Object $log} 
        'ERROR' {Write-Host -ForegroundColor Red -Object $log} 
        'COMMENT' {Write-Host -ForegroundColor GREY -Object $log} 
    } 
}

# Fichier de log à l'emplacement du script $source_dir
$source_dir = Get-Script-Directory
Write-Host $sourc_dir
$logfile = $source_dir + "\TraitementRepertoiresOwnersv2.log"
#$transcriptfile = $source_dir + "\Transcript_TraitementRepertoiresOwnersv2.log"
Write-host "Fichier de log : $logfile"
#Start-Transcript -Path F:\Scripts\Share\TraitementRepertoiresRacinesv2.log -Append
#Start-Transcript -Path $transcriptfile -Append

Import-Module "PSCX"
Set-Privilege (new-object Pscx.Interop.TokenPrivilege "SeRestorePrivilege", $true) #Necessary to set Owner Permissions
Set-Privilege (new-object Pscx.Interop.TokenPrivilege "SeBackupPrivilege", $true) #Necessary to bypass Traverse Checking
Set-Privilege (new-object Pscx.Interop.TokenPrivilege "SeTakeOwnershipPrivilege", $true) #Necessary to override FilePermissions & take Ownership

# Scan des répertoires racines
$path = "P:\SHARE\Design & Concept\"
Write-Host "Dossier sélectionné pour le traitement : $path"

Try
{
    $dir = Get-ChildItem -Recurse -Path $path -ErrorAction SilentlyContinue
}
Catch
{
     Out-Log -Name "Droits insuffisants" -Msg "$chemin, Owner non trouvé, Pb de droit" -type ERROR
}

$count_files = 0
$count_folders = 0
foreach ($d in $dir)
{
    $directoryName = $d.DirectoryName
    Write-host $d.Name in $directoryName -ForegroundColor Green
    #$acl = Get-Acl -Path "F:\Scripts\$d"
    #$acl.access.IdentityReference

    # Récupération des acls non hérités et de l'acl du dossier
    #$aclaccess = Get-Acl -Path "$path$d" | Select-Object -ExpandProperty Access | Where-Object { -Not $_.IsInherited }
    $chemin = "$directoryName\$d"
    Write-host $chemin -ForegroundColor Blue

    Try
    {
        $aclfolder = Get-Acl -Path $chemin -ErrorAction SilentlyContinue
        $owner = $aclfolder.Owner
        Write-Host "Owner du $chemin : $owner"
    }
    Catch
    {
        Write-Host "$chemin"
        #Changement du owner par Admins du domaine
        $Account = New-Object System.Security.Principal.NTAccount("dom_smb\Admins du domaine")
        $FileSecurity = new-object System.Security.AccessControl.FileSecurity
        $FileSecurity.SetOwner($Account)
        [System.IO.File]::SetAccessControl($chemin, $FileSecurity)

        $aclfolder = Get-Acl -Path $chemin # -ErrorAction SilentlyContinue
        $owner = $aclfolder.Owner

        if ($d.Attributes -like "Directory")
        {
            $count_folders ++
            Write-Host "Owner du dossier $chemin : $owner" -ForegroundColor Magenta
            Out-Log -Name "Owner change" -Msg "$chemin, $owner, folder" -type INFO
        }
        else
        {
            $count_files ++
            Write-Host "Owner du fichier $chemin : $owner" -ForegroundColor DarkMagenta
            Out-Log -Name "Owner change" -Msg "$chemin, $owner, file" -type INFO
        }
        #Write-Host "TOTO" -ForegroundColor Red
    }

    <#
    if ($aclfolder.AreAccessRulesProtected -eq $false)
    {
        Write-host $aclaccess.count -ForegroundColor Red
        $aclfolder
        $aclfolder.Access
        $count ++
        $perm = 'Everyone', 'Delete', 'None', 'None', 'Deny'
        $rule = New-Object -TypeName System.Security.AccessControl.FileSystemAccessRule -ArgumentList $perm
        $aclfolder.SetAccessRule($rule)
        $aclfolder | Set-Acl -Path "$path$d"
    }#>

}
write-host "Nb de fichiers sans groupe Admins : $count_files"
write-host "Nb de dossiers sans groupe Admins : $count_folders"
$Script:journal | Export-csv -Path $logfile -Append

#Stop-Transcript

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