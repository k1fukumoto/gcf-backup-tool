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


function PrintUsage() {
	$script_base = Split-path $script:MyInvocation.MyCommand.Path -Leaf
	Write-Host ("Usage: {0} <VM name pattern>" -f $script_base)
}

$vmname = $args[0]
if($vmname -eq $null) {
	PrintUsage
	exit
}

$vm_h = @{}
Get-Content $LOG | Select-String -Pattern "^(.{16}).*VMPATH:(/.+/.+/.+)/(.*$($vmname).+\(.+\))" | %{
	$date = $_.Matches.Groups[1].Value
	$path = $_.Matches.Groups[2].Value
	$vm = $_.Matches.Groups[3].Value
	
	$path_h = $vm_h.Get_Item($vm)
	if($path_h) {
		$path_h.Set_Item('to',$date)
	} else {
		$vm_h.Add($vm,@{'path'=$path; 'from'=$date; 'to'=$date})
	}
}
$vm_h.GetEnumerator() | %{
	Write-Host ""
	Write-Host ("{0}" -f $_.Name)
	Write-Host ("{0}-{1}" -f $_.Value.Get_Item('from'),$_.Value.Get_Item('to'))
	Write-Host ("{0}" -f $_.Value.Get_Item('path'))
}