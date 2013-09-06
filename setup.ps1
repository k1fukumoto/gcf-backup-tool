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

Read-Host -AsSecureString "Enter vCenter access user password" | ConvertFrom-SecureString | Set-Content $VC_PASS
Read-Host -AsSecureString "Enter vCloud Director access user password" | ConvertFrom-SecureString | Set-Content $VCD_PASS
Read-Host -AsSecureString "Enter Avamar Utility Node access user password" | ConvertFrom-SecureString | Set-Content $AVM_PASS
