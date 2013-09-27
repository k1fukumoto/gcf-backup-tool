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

function CreateRow ($vm,$gname) {
	$row = New-Object PsObject -Property @{
		'VM' = $vm.Name;
		'GNAME' = $gname;
	}
	return $row
}

function FindGeneration($dspath) {
	$maps = $cfg.'backup-config'.'datastore-maps'.'datastore-map'
	foreach($m in $maps){
		if ($dspath -like $m.pattern) {
			return $m.generation
		}
	}
	return $null
}
function FindGroup($gen,$order) {
	if(!$gen) {return $null}
	
	$groups = $cfg.'backup-config'.groups.group
	foreach ($g in $groups) {
		if ($gen -eq $g.generation -and $order.'start-time' -eq $g.'start-time') {
			return $g.name
		}
	}
	return $null
}

# Load backup configuration
try {
	[xml]$cfg = Get-Content $BACKUP_CFG
} catch {
	ERROR("Execution Aborted >> '{0}'" -f $_)
	$_
	exit
}

# Connect to vCenter
$acct = $cfg.'backup-config'.account

$cred = New-Object System.Management.Automation.PSCredential($acct.vcenter.user, (Get-Content $VC_PASS | ConvertTo-SecureString))
$vc = Connect-VIServer -Server $acct.vcenter.hostname -Credential $cred

# Connect to vCloud Director
$cred = New-Object System.Management.Automation.PSCredential($acct.'vcloud-director'.user, (Get-Content $VCD_PASS | ConvertTo-SecureString))
$vcd = Connect-CIServer -Server $acct.'vcloud-director'.hostname -Credential $cred

$vmlist = @()
$cfg.'backup-config'.orders.order | %{
	$order = $_
	INFO ("Fetching VDC '{0}'" -f $_.orgvdc)
	$vdc = Get-OrgVdc $_.orgvdc
	if($vdc -eq $null) {throw "VDC {0} not found" -f $_.orgvdc}
	$vdc | Get-CIVM | % {
		$vsvm = Get-VM -Name ("*{0}*" -f $_.Id.split(':')[3])		
	
		if($vsvm -eq $null) {
			# This happens if VM is "Failed to create" status on vCD. It only exists in vCD world.
            INFO("Skip VM '{0}'. 'Failed to Create' status on vCD" -f $_.Name)
			return
		}
		
        # All harddisks are stored in the same datastore. Pick the first HDD.
		# Oddly, Get-HardDisk returns single object, if VM has only one harddisk.
        $hdd = Get-HardDisk -VM $vsvm
        if($hdd -is [array]) {$hdd = $hdd[0]} 
				
        # Convert VMFS file path to datastore name^
        $dspath = $null
		if($hdd.FileName -match '^\[(\S+)\] ') {
            $dspath = $matches[1]
        } else {
            Throw "Mulformatted VMFS path '{0}'" -f $hdd.FileName
        }
               
        # Map datastore path to backup generation
        $gen = FindGeneration $dspath
        if ($gen -eq $null) {
            INFO("Skip VM '{0}'. Not backup target" -f $vsvm.Name)
        } else {
			# Finally, map (generation, start-time) pair to group name
            $gname = FindGroup $gen $order
            if($gname) {
				INFO("Map VMPATH:/{0}/{1}/{2}/{3} to {4}" -f $vdc.Org.Name, $vdc.Name, $_.VApp.Name, $vsvm.Name, $gname)
				$vmlist += (CreateRow $vsvm $gname)
            } else {
                Throw "Wrong start-time '{0}' for vDC '{1}'" -f $order.'start-time',$vdc.Name
            }
		}
	}
}

$vmlist | Export-Csv -NoTypeInformation $BACKUP_TARGET

