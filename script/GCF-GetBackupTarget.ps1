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

function FindGeneration($ds) {
	$maps = $cfg.'backup-config'.'datastore-maps'.'datastore-map'
	foreach($m in $maps){
		if ($ds.Name -like $m.pattern) {
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
		$datastores = $vsvm | Get-Datastore 
		# At least 2 datastores are returned for each VM. One for VMX file, and the other for disks.
		# VCD doesn't allow to create VM which spans multiple storage profiles/datastores.
		# Just pick the first datastore.
		foreach($ds in $datastores) {
			$gen = FindGeneration $ds
			if ($gen -eq $null) {
				INFO("VM '{0}' is not backup target" -f $vsvm.Name)
				break
			} 
			
			$gname = FindGroup $gen $order
			if($gname) {
				INFO("VM '{0}' is mapped to '{1}'" -f $vsvm.Name, $gname) 
				$vmlist += (CreateRow $vsvm $gname)
			} else {
				Throw "Wrong start-time '{0}' for vDC '{1}'" -f $order.'start-time',$order.orgvdc	
			}
			break
		}
	}
}

$vmlist | Export-Csv -NoTypeInformation $BACKUP_TARGET

