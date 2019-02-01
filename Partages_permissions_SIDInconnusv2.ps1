# A definir
$fichierSource = "MonShowRoomSID.csv"
#$log
if ($fichierSource -eq "") {$fichierSource = Read-Host "Nom du fichier source (ex. : test.csv)"}

function Get-Script-Directory
{
    $scriptInvocation = (Get-Variable MyInvocation -Scope 1).Value
    return Split-Path $scriptInvocation.MyCommand.Path
}

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

#Traitement des dossiers avec un ACL Locked
#P/Invoke'd C# code to enable required privileges to take ownership and make changes when NTFS permissions are lacking
$AdjustTokenPrivileges = @"
using System;
using System.Runtime.InteropServices;

 public class TokenManipulator
 {
  [DllImport("advapi32.dll", ExactSpelling = true, SetLastError = true)]
  internal static extern bool AdjustTokenPrivileges(IntPtr htok, bool disall,
  ref TokPriv1Luid newst, int len, IntPtr prev, IntPtr relen);
  [DllImport("kernel32.dll", ExactSpelling = true)]
  internal static extern IntPtr GetCurrentProcess();
  [DllImport("advapi32.dll", ExactSpelling = true, SetLastError = true)]
  internal static extern bool OpenProcessToken(IntPtr h, int acc, ref IntPtr
  phtok);
  [DllImport("advapi32.dll", SetLastError = true)]
  internal static extern bool LookupPrivilegeValue(string host, string name,
  ref long pluid);
  [StructLayout(LayoutKind.Sequential, Pack = 1)]
  internal struct TokPriv1Luid
  {
   public int Count;
   public long Luid;
   public int Attr;
  }
  internal const int SE_PRIVILEGE_DISABLED = 0x00000000;
  internal const int SE_PRIVILEGE_ENABLED = 0x00000002;
  internal const int TOKEN_QUERY = 0x00000008;
  internal const int TOKEN_ADJUST_PRIVILEGES = 0x00000020;
  public static bool AddPrivilege(string privilege)
  {
   try
   {
    bool retVal;
    TokPriv1Luid tp;
    IntPtr hproc = GetCurrentProcess();
    IntPtr htok = IntPtr.Zero;
    retVal = OpenProcessToken(hproc, TOKEN_ADJUST_PRIVILEGES | TOKEN_QUERY, ref htok);
    tp.Count = 1;
    tp.Luid = 0;
    tp.Attr = SE_PRIVILEGE_ENABLED;
    retVal = LookupPrivilegeValue(null, privilege, ref tp.Luid);
    retVal = AdjustTokenPrivileges(htok, false, ref tp, 000000000000000000000000000000000000000000000, IntPtr.Zero, IntPtr.Zero);
    return retVal;
   }
   catch (Exception ex)
   {
    throw ex;
   }
  }
  public static bool RemovePrivilege(string privilege)
  {
   try
   {
    bool retVal;
    TokPriv1Luid tp;
    IntPtr hproc = GetCurrentProcess();
    IntPtr htok = IntPtr.Zero;
    retVal = OpenProcessToken(hproc, TOKEN_ADJUST_PRIVILEGES | TOKEN_QUERY, ref htok);
    tp.Count = 1;
    tp.Luid = 0;
    tp.Attr = SE_PRIVILEGE_DISABLED;
    retVal = LookupPrivilegeValue(null, privilege, ref tp.Luid);
    retVal = AdjustTokenPrivileges(htok, false, ref tp, 0, IntPtr.Zero, IntPtr.Zero);
    return retVal;
   }
   catch (Exception ex)
   {
    throw ex;
   }
  }
 }
"@

add-type $AdjustTokenPrivileges


Function DeleteSID([string]$path,[string]$sid)
{  
  	try
  	{
   		#This function is used to delete the orphaned SID 
   		$acl = Get-Acl -Path $Path
   		foreach($acc in $acl.access)
   		{
   			$value = $acc.IdentityReference.Value
   			if($value -eq $sid)
   			{
                # Désactivation de l'héritage du dossier tout en conservant les objets (pas de suppression)
                #$acl.SetAccessRuleProtection($true,$true)
                #Set-Acl -Path $Path -AclObject $acl
                $droits = $acc.FileSystemRights
   				$acl.RemoveAccessRule($acc) | Out-Null
   				Set-Acl -Path $Path -AclObject $acl -ErrorAction Stop
                Write-Host "Suppression du user $value pour $Path" -ForegroundColor Green
                Out-Log -Name "Right" -Msg "Suppression, $value, $droits, $Path" -type INFO
                # Réactivation de l'héritage du dossier
                #$acl.SetAccessRuleProtection($false,$false)
                #Set-Acl -Path $Path -AclObject $acl
   			}
   		}
  	}
   	catch
   	{
   		Write-Error $Error
   	}
}

#Récupération du répertoire où se trouve le script
$source_dir = Get-Script-Directory

# chemin du fichier CSV source (rapport Varonis)
$source = $source_dir + "\" + $fichierSource

if (Test-Path -Path $source)
{
    write-host "Fichier utilisé pour le traitement : $source"
}
Else
{
    write-host "Fichier source non trouvé : $source"
}

$csv = Import-Csv -Delimiter "," -Path $source
$total = $csv.count
write-host "Nombre de SID inconnus a traiter : $total"

$i=1
#Traitement du fichier CSV source
$csv | % {
            Write-Progress -Activity "Traitement des SID inconnus" -status "SID numero $i sur $total" -percentComplete (($i / $total)*100)
            #$user = "DOM_SMB\" + $_.SID
            $user = $_.SID
            $fileserver = $_.'File Server'
            $path = $_.'Access Path'
            write-host "PATH : $path"
            if ($path -eq "C:" -or $path -eq "D:" -or $path -eq "E:" -or $path -eq "F:" ) {$pathUNC = $path}
            Else
            {
                $letter = (Split-Path $path)[0]
                $pathUNC = Split-Path $path -NoQualifier
                $pathUNC = "\\" + $fileserver + "\" + $letter + "$" + $pathUNC
            }
            write-host "CHEMIN : $pathUNC"
            $i++

            Try
            {
                $acl = get-acl -Path $pathUNC -ErrorAction Stop
                #Récupération du Owner du dossier pour déterminer si il est nécessaire de le changer
                $owner = $acl.Owner
                $userSID = "O:$user"
                Write-Host "$owner - compare - $user"
                if ($owner -eq $userSID)
                {
                    Write-Host "Remplacement du Owner ($owner) par DOM_SMB\Admin du Domaine pour $pathUNC"
                    Out-Log -Name "Owner" -Msg "Remplacement, $owner, FullAccess, $pathUNC" -type INFO

                    #Suppression de la permission pour utilisateur désactivé
                    DeleteSID -path $pathUNC -sid $user

                    $Account = New-Object System.Security.Principal.NTAccount("dom_smb\Admins du domaine")
                    $FileSecurity = new-object System.Security.AccessControl.FileSecurity
                    $FileSecurity.SetOwner($Account)
                    [System.IO.File]::SetAccessControl($pathUNC, $FileSecurity)
                }
                else
                {
                    #Suppression de la permission pour utilisateur désactivé                                            }
                    DeleteSID -path $pathUNC -sid $user
                }
            }
            Catch
            {
                $ErrorMessage = $_.Exception.Message
                $FailedItem = $_.Exception.ItemName
                #Write-Host "Acces impossible au dossier $pathUNC"
                Write-Host $ErrorMessage
                Out-Log -Name "FolderAccess" -Msg "Acces impossible, $user, , $pathUNC" -type ERROR
                #Break
            }
        }

Write-Host "Sortie du fichier résultat $fichierSource.log"
$logfile = $source_dir + "\" + $fichierSource + ".log"
$logfile
$Script:journal | Export-csv -Path $logfile