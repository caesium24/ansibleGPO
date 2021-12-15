#!powershell

# Copyright: (c) 2021, Eshton Brogan
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

#Requires -Module Ansible.ModuleUtils.Legacy

$ErrorActionPreference = "Stop"

$params = Parse-Args -Arguments $args -supports_check_mode $true
$check_mode = Get-AnsibleParam -obj $params -name "_ansible_check_mode" -type "bool" -default $false
$path = Get-AnsibleParam -obj $params -name "path" -type "str" -failifempty $false
$migration_table = Get-AnsibleParam -obj $params -name "migration_table" -type "str" failifempty $false

$result = @{
    changed = $false
}

if (-not (Get-Module -Name ActiveDirectory -ListAvailable)) {
    Fail-Json $result "win_update_mig_table requires the GroupPolicy PS module to be installed"
}
Import-Module GroupPolicy

if (-not (Get-Module -Name ActiveDirectory -ListAvailable)) {
    Fail-Json $result "win_update_mig_table requires the ActiveDirectory PS module to be installed"
}
Import-Module ActiveDirectory

#? Function to compare the amount of steps it takes to change a string
#? ===================================================================
function Measure-StringDistance {

    [CmdletBinding(SupportsShouldProcess=$true)]
    [OutputType([int])]
    param (
        [Parameter(ValueFromPipelineByPropertyName=$true)]
        [string]$Source = "",
        [string]$Compare = ""
    )
    $n = $Source.Length;
    $m = $Compare.Length;
    $d = New-Object 'int[,]' $($n+1),$($m+1)
        
    if ($n -eq 0){
        return $m
    }
    if ($m -eq 0){
        return $n
    }

    for ([int]$i = 0; $i -le $n; $i++){
        $d[$i, 0] = $i
    }
    for ([int]$j = 0; $j -le $m; $j++){
        $d[0, $j] = $j
    }

    for ([int]$i = 1; $i -le $n; $i++){
        for ([int]$j = 1; $j -le $m; $j++){
            if ($Compare[$($j - 1)] -eq $Source[$($i - 1)]){
                $cost = 0
            }
            else{
                $cost = 1
            }
            $d[$i, $j] = [Math]::Min([Math]::Min($($d[$($i-1), $j] + 1), $($d[$i, $($j-1)] + 1)),$($d[$($i-1), $($j-1)]+$cost))
        }
    }      
    return $d[$n, $m]
}
#? ===================================================================

$target_domain = Get-ADDomain
$backup_dict = @()
$compared_list = @()
$targets = (Get-ADUser -Filter *) + (Get-ADGroup -Filter *)

if((Test-Path $migration_table -PathType Leaf) -eq $true){
    $mig_table = Get-Content $migration_table
    $mig_table | foreach {$_ -replace "<DestinationSameAsSource />","<Destination></Destination>"} | Set-Content $migration_table
    [xml]$xml = Get-Content -Path $migration_table
    $sources = $xml.MigrationTable.Mapping.source | Where-Object {$_ -like "*@*"}
}
else{
    Fail-Json $result "$migration_table can not be found or does not exist"
}

foreach($source in $sources){
    $object_list = @()
    $source_name = $source -replace '@.*$', ''
    foreach($target in $targets){
        $outcome = Measure-StringDistance $source_name $target.name
            $obj = @(

                [PSCustomObject]@{
                    source_name = $source
                    target_name = $target.name
                    diff = $outcome
                }
            )
        $object_list += $obj
    }
    $min = $object_list.diff | Measure -Minimum
    $compared_list += ($object_list | Where-Object {$_.diff -eq $min.minimum})
}

if($null -ne $compared_list){
    foreach($mapping in $xml.MigrationTable.Mapping){
        foreach($object in $compared_list){
            if($mapping.source -like $object.source_name){
                $mapping.destination = ($object.target_name) + "@" + ($target_domain.DNSRoot)
                $xml.save($migration_table)
            }
            elseif($mapping.source -like "ADD YOUR DOMAIN ADMINS"){
                $mapping.destination = "Domain Admins" + "@" + ($target_domain.DNSRoot)
                $xml.save($migration_table)
            }
            elseif($mapping.source -like "ADD YOUR ENTERPRISE ADMINS"){
                $mapping.destination = "Enterprise Admins" + "@" + ($target_domain.DNSRoot)
                $xml.save($migration_table)
            }
        }
    }
    foreach($mapping in $xml.MigrationTable.Mapping){
        if($mapping.destination -eq ''){
            $mapping.destination = $mapping.source
            $xml.save($migration_table)
        }
    }
}
else{
    Fail-Json $result "No sources could be compared to target domain accounts"
}
$result.changed = $true
Exit-Json -obj $result
