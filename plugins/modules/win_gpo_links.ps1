#!powershell

# Copyright: (c) 2020, Eshton Brogan
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

#Requires -Module Ansible.ModuleUtils.Legacy

$params = Parse-Args -arguments $args -supports_check_mode $true
$check_mode = Get-Ansibleparam -name "_ansible_check_mode" -type "bool" -default $false

$name = Get-AnsibleParam -obj $params -name "name" -type "str" -failifempty $true
$state = Get-AnsibleParam -obj $params -name "state" -type "str" -default "present" -ValidateSet "absent", "present"
$enforced = Get-AnsibleParam -obj $params -name "enforced" -type "bool"
$enabled = Get-AnsibleParam -obj $params -name "enabled" -type "bool" 
$target = Get-AnsibleParam -obj $params -name "target" -type "str"
$wmi_filter_name = Get-AnsibleParam -obj $params -name "wmi_filter_name" -type "str"

if (-not $target) {
    $target = (Get-ADRootDSE).defaultNamingContext
}

$result = @{
    changed = $false
}

$link = (Get-GPInheritance -Target $target).GpoLinks | Where-Object { $_.DisplayName -eq $name }
if ($state -eq "present") {
    if (-not $link) {
        $link = New-GPLink -Name $name -Target $target -WhatIf:$check_mode
        $result.changed = $true
    }

    if ($null -ne $enabled -and $link.Enabled -ne $enabled) {
        $enabled_value = if ($enabled) { "yes" } else { "no" }
        $link = $link | Set-GPLink -LinkEnabled $enabled_value -WhatIf:$check_mode
        $result.changed = $true
    }

    if ($null -ne $enforced -and $link.Enforced -ne $enforced) {
        $enforced_value = if ($enforced) { "Yes" } else { "No" }
        $link = $link | Set-GPLink -Enforced $enforced_value -WhatIf:$check_mode
        $result.changed = $true
    }

    if ($null -ne $wmi_filter_name) {
        try{
            $myDomain = [System.Net.NetworkInformation.IpGlobalProperties]::GetIPGlobalProperties().DomainName
    
            try{
                $GPO = Get-GPO -Name "$name"
            }
            catch{
                $Msg = $_.Exception.ToString()
                Fail-Json $result "$name does not exist. Error was: $Msg"
            }
    
            try{
                $filter = "msWMI-Name -eq `'" + $wmi_filter_name + "`'"
            }
            catch{
                $Msg = $_.Exception.ToString()
                Fail-Json $result "$name does not exist. Error was: $Msg"
            }
    
            $WMIFilter = Get-ADObject -filter $filter
            $WMIFilterLinkValue = "[$myDomain;" + $($WMIFilter.Name) + ";0]"
    
            try {
                Set-ADObject $($GPO.Path) -Add @{gPCWQLFilter=$WMIFilterLinkValue}
            }
            catch {
                Set-ADObject $($GPO.Path) -Replace @{gPCWQLFilter=$WMIFilterLinkValue}
            }
            $result.changed = $true
        }
        catch{
            $Msg = $_.Exception.ToString()
            Fail-Json $result "Domain does not exist. Error was: $Msg"
            $result.changed = $false
        }
    }
}
else {
    if ($link) {
        $link | Remove-GPLink -WhatIf:$check_mode
        $result.changed = $true
    }
}

Exit-Json -obj $result
