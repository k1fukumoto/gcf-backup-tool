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
$INSTALL_DIR = Split-path (Split-path $script:MyInvocation.MyCommand.Path)

# Log File Location
$LOG = "$INSTALL_DIR\log\GCF-SyncBackupJob.log"
# Log size limit in KB. Log will be renamed once size reaches this number
$LOGMAX = 1024 # KB

# Backup configuration
$BACKUP_CFG = "$INSTALL_DIR\config\backup-config.xml"

# Credential stores
$VC_PASS = "$INSTALL_DIR\config\.vcpass.crd"
$VCD_PASS  = "$INSTALL_DIR\config\.vcdpass.crd"
$AVM_PASS =  "$INSTALL_DIR\config\.avmpass.crd"

# Interim report data
$BACKUP_TARGET = "$INSTALL_DIR\output\backup-target.csv"
$BACKUP_JOB = "$INSTALL_DIR\output\backup-job.csv"
$TMP_MCCLI = "$INSTALL_DIR\output\mccli.xml"

# Logging facility
function INFO ($s) {
	$l = "$(Get-Date) INFO: {0}" -f $s
	Write-Host $l -ForegroundColor Gray
	$l | Out-File $LOG -Append -Encoding ASCII
}
function ERROR ($s) {
	$l = "$(Get-Date) ERROR: {0}" -f $s
	Write-Host $l -ForegroundColor Red
	$l | Out-File $LOG -Append -Encoding ASCII
}
