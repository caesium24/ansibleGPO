#!powershell

# Copyright: (c) 2020, Eshton Brogan
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

#Requires -Module Ansible.ModuleUtils.Legacy

$ErrorActionPreference = "Stop"

$params = Parse-Args -Arguments $args -supports_check_mode $true
$check_mode = Get-AnsibleParam -obj $params -name "_ansible_check_mode" -type "bool" -default $false

$state = Get-AnsibleParam -obj $params -name "state" -type "str" -default "present" -validateset "absent", "present"
$gpo_name = Get-AnsibleParam -obj $params -name "gpo_name" -type "str" -failifempty $false
$domain = Get-AnsibleParam -obj $params -name "domain" -type "str" -failifempty $false
$migration_table = Get-AnsibleParam -obj $params -name "migration_table" -type "str" failifempty $false
$path = Get-AnsibleParam -obj $params -name "path" -type "str" -failifempty $false

$result = @{
    changed = $false
    text = "0"
}

if (-not (Get-Module -Name ActiveDirectory -ListAvailable)) {
    Fail-Json $result "win_gpo_import requires the GroupPolicy PS module to be installed"
}
Import-Module GroupPolicy

switch ($state.ToLower()){

    'absent'{
        Remove-GPO -Name $gpo_name -WhatIf: $check_mode
        }

    'present'{
        $domain_gpos = Get-GPO -All
        $gpos = Get-ChildItem -Recurse -Force -Path $path | Where-Object {$_.FullName -like "*bkupinfo.xml"}
        
        if ($state -eq "present" -and $null -ne $gpos) {
            foreach ($gpo in $gpos) {
                [xml]$xml = Get-Content -Path $gpo.FullName
                $custom_id = $xml.BackupInst.ID.innertext
                $custom_name = $xml.BackupInst.GPODisplayName.innertext
                    try{
                        Import-GPO `
                        -BackupId $custom_id `
                        -TargetName $custom_name `
                        -Domain $domain `
                        -Path "$($gpo.DirectoryName)\..\" `
                        -CreateIfNeeded `
                        -MigrationTable $migration_table `
                        -WhatIf: $check_mode
                        $changed_gpos = Get-GPO -all
                            if($null -eq (Compare-Object -ReferenceObject $domain_gpos -DifferenceObject $changed_gpos)){
                                $result.changed = $false
                            }
                            else{
                                $result.changed = $true
                                $result.text = "$changed_gpos"
                            }
                    }
                    catch{
                        $Msg = $_.Exception.ToString()
                        Fail-Json $result "$custom_name was not imported. Error was: $Msg"
                        $result.changed = $false
                    }
            }
        }
        else{
            Fail-Json $result "GPO was not imported"
            $result.changed = $false
        }
    }
}
Exit-Json -obj $result
