#!powershell

# Copyright: (c) 2021, Eshton Brogan
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

#Requires -Module Ansible.ModuleUtils.Legacy

$ErrorActionPreference = "Stop"

$params = Parse-Args -Arguments $args -supports_check_mode $true
$check_mode = Get-AnsibleParam -obj $params -name "_ansible_check_mode" -type "bool" -default $false
$path = Get-AnsibleParam -obj $params -name "path" -type "str" -failifempty $true
$migration_table = Get-AnsibleParam -obj $params -name "migration_table" -type "str" failifempty $true

$result = @{
  changed = $false
}

if (-not (Get-Module -Name ActiveDirectory -ListAvailable)) {
  Fail-Json $result "win_generate_mig_table requires the GroupPolicy PS module to be installed"
}
Import-Module GroupPolicy

$path_list = @()
$gpo_dirs = Get-ChildItem -Path $path -Recurse -Force | Where-Object {$_.Name -like "{*}"}

if($null -ne $gpo_dirs){
  $gpm = New-Object -comobject gpmGMT.gpm
  $constants = $gpm.GetConstants()
  foreach($dir in $gpo_dirs.FullName){
    $gpo_path = $dir -replace '{.*}$', ''
    $path_list += $gpo_path
}
}
else{
  Fail-Json $result "No Group Policy Objects found in $path"
}

foreach($gpo in $path_list){
  $strBackup = $gpm.GetBackupDir($gpo)
  $gpmSearchCriteria = $gpm.CreateSearchCriteria()
  $backup_list += $strBackup.SearchBackups($gpmSearchCriteria)
}

$mig_table = $gpm.CreateMigrationTable()

if($null -ne $backup_list){
  foreach($gpo in $backup_list){
    $sec = $constants.ProcessSecurity
    $mig_table.Add($sec,$gpo)
  }
}
else{
  Fail-Json $result "No Group Policy Objects found in backups"
}

$mig_table.Save($migration_table)

if((Test-Path $migration_table -PathType Leaf) -eq $true){
  $result.changed = $true
}
else{
  Fail-Json $result "Migration Table was not created"
}
Exit-Json -obj $result
