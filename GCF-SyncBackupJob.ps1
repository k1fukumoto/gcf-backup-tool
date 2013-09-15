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
[CmdletBinding()]
Param(
	[switch]$rotateLog,
	[switch]$queryTarget,
	[switch]$queryBackupJob,
	[switch]$updateBackupJob,
	[switch]$all	
)
. .\config\environment.ps1

function RotateLog($log) {
	if(!(Test-Path $log)) {return}
	
    $fd = Get-Item $log
    $filesize = $fd.length/1KB
	
    if ($filesize -gt $LOGMAX) {
		$newname = ("{0}_{1}.log" -f 
					($fd.fullname -replace '\.log$',''), 
					(Get-Date -uformat "%Y%m%d-%H%M"))
        Rename-Item -Path $fd.fullname -NewName $newname
		INFO("----- Log file is rotated. Old logs are archived in $($newname) -----")
    }
}

if($all) {
	$rotateLog = $queryTarget = $queryBackupJob = $updateBackupJob = $true
}

try {
	if($rotateLog) {
		RotateLog($LOG)
	}
	if($queryTarget) {
		.\script\GCF-GetBackupTarget.ps1		
	}
	if($queryBackupJob) {
		.\script\GCF-GetBackupJob.ps1
	}
	if($updateBackupJob) {
		.\script\GCF-UpdateBackupJob.ps1
	}
}
catch {
	ERROR("Execution Aborted >> {0}" -f $_)
	$_
}
