#######################################################################################
# Copyright 2013 VCE All Rights Reserved
#
# You may freely use and redistribute this script as long as this 
# copyright notice remains intact 
#
#
# DISCLAIMER. THIS SCRIPT IS PROVIDED TO YOU "AS IS" WITHOUT WARRANTIES OR CONDITIONS 
# OF ANY KIND, WHETHER ORAL OR WRITTEN, EXPRESS OR IMPLIED. THE AUTHOR SPECIFICALLY 
# DISCLAIMS ANY IMPLIED WARRANTIES OR CONDITIONS OF MERCHANTABILITY, SATISFACTORY 
# QUALITY, NON-INFRINGEMENT AND FITNESS FOR A PARTICULAR PURPOSE. 
#
#######################################################################################

. .\config\environment.ps1

function load-csv ($csv) {
	$ret = @{}
	$lines = Import-Csv $csv
	foreach($l in $lines)  {
		if ($l -eq $null -or $l.vm -eq $null) {continue}
		$a = $ret.Get_Item($l.vm)
		if($a -eq $null) {
			$ret.Add($l.vm,$l.gname)
		} else {
			ERROR("Duplicated VM entry '{0}'" -f $l.vm)
		}
	}
	return $ret
}

function AvamarRunCmd($cmd) {
	INFO ("Execute Avamar Command '$ {0}'" -f $cmd)
	.\plink.exe "$($acct.user)@$($acct.hostname)" -ssh -pw $p $cmd > $TMP_MCCLI
	[xml]$ret = Get-Content $TMP_MCCLI
	return [int]$ret.CLIOutput.Results.ReturnCode
}

function AvamarLastEventCode() {
	[xml]$ret = Get-Content $TMP_MCCLI
	return [int]$ret.CLIOutput.Results.EventCode
}

function AvamarMoveClient($gname1,$gname2,$vm) {
	$group_remove = "mccli group remove-client --client-domain=$($acct.domain) --client-name='$($vm)' --domain=$($acct.domain) --name=$($gname1) --xml"
	$group_add = "mccli group add-client --client-domain=$($acct.domain) --client-name='$($vm)' --domain=$($acct.domain) --name=$($gname2) --xml"
	
	if (0 -eq (AvamarRunCmd($group_remove))) {
		INFO ("VM '{0}' removed from GROUP {1}" -f $vm, $gname1)
		if(0 -eq (AvamarRunCmd($group_add))) {
			INFO ("VM '{0}' added to GROUP {1}" -f $vm, $gname2)
		} else {
			ERROR("Failed to add VM '{0}' to GROUP {1}: {2}" -f $vm, $gname2, $group_add)
		}	
	} else {
		ERROR("Failed to remove VM '{0}' from GROUP {1}: {2}" -f $vm, $gname1, $group_remove)
	}	
}

function AvamarRemoveClient($gname,$vm) {
	$group_remove = "mccli group remove-client --client-domain=$($acct.domain) --client-name='$($vm)' --domain=$($acct.domain) --name=$($gname) --xml"
	
	if (0 -eq (AvamarRunCmd($group_remove))) {
		INFO ("VM '{0}' removed from GROUP {1}" -f $vm, $gname)
	} else {
		ERROR("Failed to remove VM '{0}' from GROUP {1}: {2}" -f $vm, $gname, $group_remove)
	}	
}

function AvamarAddClient($gname,$vm) {
	$folder = (Get-VM $vm | Get-FolderPath)
	$folder = ($folder.Path -replace "$($acct.datacenter)/", '')
	$vm_add = "mccli client add --type=vmachine --name='$($vm)' --datacenter=$($acct.datacenter) --domain=$($acct.domain) --folder='$($folder)' --xml"
	$group_add = "mccli group add-client --client-domain=$($acct.domain) --client-name='$($vm)' --domain=$($acct.domain) --name=$($gname) --xml"

	$addret = AvamarRunCmd($vm_add)
	$ec = AvamarLastEventCode
	$ec
	if ((0 -eq $addret) -or  (22238 -eq $ec)) {
	# Event Code: 22238 means client already exists
		INFO ("VM '$($vm)' added to Avamar")
		if(0 -eq (AvamarRunCmd($group_add))) {
			INFO ("VM '$($vm)' added to Group $($gname)")
		} else {
			ERROR("Failed to add VM '{0}' to GROUP {1}: {2}" -f $vm, $gname, $group_add)
		}	
	} else {
		ERROR("Failed to add VM '{0}' to Avamar: {1}" -f $vm, $vm_add)
	}
}

filter Get-FolderPath {
    $_ | Get-View | % {
        $row = "" | select Name, Path
        $row.Name = $_.Name
 
        $current = Get-View $_.Parent
#        $path = $_.Name # Uncomment out this line if you do want the VM Name to appear at the end of the path
        $path = ""
        do {
            $parent = $current
            if($parent.Name -ne "vm"){$path = $parent.Name + "/" + $path}
            $current = Get-View $current.Parent
        } while ($current.Parent -ne $null)
        $row.Path = $path
        $row
    }
}

# Load backup configuration
[xml]$cfg = Get-Content $BACKUP_CFG

# Load Avamar account information
$acct = $cfg.'backup-config'.account.avamar
$cred = New-Object System.Management.Automation.PSCredential($acct.user, (Get-Content $AVM_PASS | ConvertTo-SecureString))
$p = $cred.GetNetworkCredential().Password

# Load vCenter account informaiton & Connect
$vc_acct = $cfg.'backup-config'.account.vcenter
$cred = New-Object System.Management.Automation.PSCredential($vc_acct.user, (Get-Content $VC_PASS | ConvertTo-SecureString))
$vc = Connect-VIServer -Server $vc_acct.hostname -Credential $cred

$targets = load-csv($BACKUP_TARGET)
$jobs = load-csv($BACKUP_JOB)

$targets.GetEnumerator() | % {
	$vm = $_.Name
	$gname = $_.Value
	$j = $jobs.get_Item($vm)
	if($j) {
		if($gname -eq $j) {
			INFO("No change VM '{0}' in GROUP {1}" -f $vm,$gname)		
		} else {
			INFO("Move VM '{0}' from GROUP {1} to {2}" -f $vm,$j,$gname)
			AvamarMoveClient $j $gname $vm
		}
		$jobs.Remove($vm)
	} else {
		INFO("Found a new VM '{0}' in GROUP {1}" -f $vm,$gname)
		AvamarAddClient $gname $vm
	}
}
$jobs.GetEnumerator() | %{
	$vm = $_.Name
	$gname = $_.Value
	INFO("Delete VM '{0}' from GROUP {1}" -f $vm,$gname) 
	AvamarRemoveClient $gname $vm
}

