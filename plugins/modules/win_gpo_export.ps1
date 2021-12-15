#!powershell

# Copyright: (c) 2021, Eshton Brogan
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

#Requires -Module Ansible.ModuleUtils.Legacy

$ErrorActionPreference = "Stop"

$params = Parse-Args -Arguments $args -supports_check_mode $true
$check_mode = Get-AnsibleParam -obj $params -name "_ansible_check_mode" -type "bool" -default $false

$gpo_name = Get-AnsibleParam -obj $params -name "gpo_name" -type "str" -failifempty $true
$path = Get-AnsibleParam -obj $params -name "path" -type "str" -failifempty $true

$result = @{
    changed = $false
    stdout = "0"
}

if (-not (Get-Module -Name ActiveDirectory -ListAvailable)) {
    Fail-Json $result "win_gpo_export requires the GroupPolicy PS module to be installed"
}
Import-Module GroupPolicy

$gpos = Get-GPO -All
if($gpos.DisplayName.Contains($gpo_name)){
  $gpos | Where-Object {$_.DisplayName -eq $gpo_name}

  try{
    Backup-GPO `
    -Name $gpo_name `
    -Path $path `
    -WhatIf: $check_mode
    
    $result.changed = $true
    $result.stdout = "$gpo_name"

  }
  catch{
      $Msg = $_.Exception.ToString()
      Fail-Json $result "$gpo_name was not exported. Error was: $Msg"
      $result.changed = $false
  }
}
else{
    Fail-Json $result "GPO was not exported"
    $result.changed = $false
}
Exit-Json -obj $result
