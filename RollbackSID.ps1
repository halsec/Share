﻿Start-Transcript "F:\Scripts\Share\SIDInconnus\TranscriptRollback.log"

$csv = Import-Csv "F:\Scripts\Share\SIDInconnus\Entrepots_Unresolved SIDs_2018-11-09-02-20-41rollback.log"
$csvAtraiter = $csv | where {$_.Type -ne "ERROR"}

foreach ($c in $csvAtraiter)
{
    $msg = $c.Msg
    #write-host $msg
    $line = $msg.split(";")
    $action = $line[0]
    $sid = $line[1]
    $rights = $line[2]
    $path = $line[3]
    #write-host $path

    if ($action -eq "Suppression")
    {
        $acl = get-acl -LiteralPath $path
        #write-host "$action, $sid, $rights, $path"
        if ($sid -like "*S-1-15-3*" -or $sid -like "*S-1-5-83-0" -or $sid -like "*S-1-5-21-*" -or $sid -like "*S-1-15-3-4096" -or $sid -like "*-1001")
        {
            #Write-host "Traitement $sid" -ForegroundColor Green
            if ($rights -like "Full Control" -or $rights -like "-2147483642")
            {
                $acl.SetSecurityDescriptorSddlForm( ($acl.sddl + "(A;OICI;FA;;;$sid)") )
                Set-Acl -Path $path -AclObject $acl
                #$acl.access
                write-host "Creation ok pour $sid, $rights    -   $path"
            }
            
            <#if ($rights -like "*ReadAndExecute*")
            {
                $acl.SetSecurityDescriptorSddlForm( ($acl.sddl + "(A;OICI;0x1200a9;;;$sid)") )
                Set-Acl -Path $path -AclObject $acl
                #$acl.access
                write-host "Creation ok pour $sid, $rights    -   $path"
            }#>
            if ($rights -like "DeleteSubdirectoriesAndFiles, Delete*")
            {
            $acl.SetSecurityDescriptorSddlForm( ($acl.sddl + "(A;OICIIO;DTSD;;;$sid)") )
            Set-Acl -Path $path -AclObject $acl
            #$acl.access
            write-host "Creation ok pour $sid, $rights    -   $path"
            }
            if ($rights -eq "268435456")
            {
                $acl.SetSecurityDescriptorSddlForm( ($acl.sddl + "(A;OICI;FA;;;$sid)") )
                Set-Acl -Path $path -AclObject $acl
                #$acl.access
                write-host "Creation ok pour $sid, $rights    -   $path"
            }
        }
    }
}

Stop-Transcript