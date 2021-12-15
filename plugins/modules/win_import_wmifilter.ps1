# Copyright: (c) 2020, Eshton Brogan
# Module was adapted from Chris Kennedy and Fred Armstrong's ImportGPOs.ps1
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

#Requires -Module Ansible.ModuleUtils.Legacy

$ErrorActionPreference = "Stop"

$params = Parse-Args -Arguments $args -supports_check_mode $true
$check_mode = Get-AnsibleParam -obj $params -name "_ansible_check_mode" -type "bool" -default $false

$mof_file = Get-AnsibleParam -obj $params -name "mof_file" -type "str" -failifempty $true

$result = @{
    changed = $false
}

$WMIFilters = $null
$WMIFilters = @()
$ADdomain = Get-ADDomain
$ADdomain_join = ($ADDomain.Forest.Split('.')) -Join ',DC='


$search = new-object System.DirectoryServices.DirectorySearcher([adsi]("LDAP://CN=SOM,CN=WMIPolicy,CN=System,DC=$($ADdomain_join)"))
$search.filter = '(objectclass=msWMI-Som)'
$checks = $search.FindAll()

$WMIFilters += foreach ($check in $checks) {

$GUID = $check.properties.'mswmi-id'
$NAME = $check.properties.'mswmi-name'
$DESCRIPTION = $check.properties.'mswmi-parm1'
$AUTHOR = $check.properties.'mswmi-author'
$CHANGEDATE = $check.properties.'mswmi-changedate'
$CREATIONDATE = $check.properties.'mswmi-creationdate'
$WQL = $check.properties.'mswmi-parm2'

    [PSCustomObject]@{
        GUID     = $GUID
        Name = $NAME
        Description = $DESCRIPTION 
        Author = $AUTHOR
        ChangeDate = $CHANGEDATE
        CreationDate = $CREATIONDATE
        WQL = $WQL
    }
}

if((Test-Path -Path $mof_file) -eq $false){
    Fail-Json $result "$mof_file file was not found"
    $result.changed = $false
}

try{
    $WMIFilter_imported = Get-Content $mof_file | ForEach-Object { if($_ -like "*=*"){$_} } | ConvertFrom-StringData

    $msWMIAuthor = "$env:USERNAME@" + [System.DirectoryServices.ActiveDirectory.Domain]::getcurrentdomain().name

    $WMIGUID = [string]"{"+([System.Guid]::NewGuid())+"}"
    $WMIDN = "CN="+$WMIGUID+",CN=SOM,CN=WMIPolicy,CN=System,"+$ADdomain.DistinguishedName
    $WMICN = $WMIGUID
    $WMIdistinguishedname = $WMIDN
    $WMIID = $WMIGUID

    $now = (Get-Date).ToUniversalTime()
    $msWMICreationDate = ($now.Year).ToString("0000") + ($now.Month).ToString("00") + ($now.Day).ToString("00") + ($now.Hour).ToString("00") + ($now.Minute).ToString("00") + ($now.Second).ToString("00") + "." + ($now.Millisecond * 1000).ToString("000000") + "-000" 
    $msWMIName = $WMIFilter_imported.Name.replace('"','').replace(';','')
    $msWMIParm1 = $msWMIName + " "
    $query = ($WMIFilter_imported.Query -replace "(^`")(.*)(`";$)",'$2')
    $queryLength = "$($query.Length)"
    $msWMIParm2 = "1;3;10;" + $queryLength + ";WQL;root\CIMv2;" + $query + ';'

    $Attr = @{"msWMI-Name" = $msWMIName;"msWMI-Parm1" = $msWMIParm1;"msWMI-Parm2" = $msWMIParm2;"msWMI-Author" = $msWMIAuthor;"msWMI-ID"=$WMIID;"instanceType" = 4;"showInAdvancedViewOnly" = "TRUE";"distinguishedname" = $WMIdistinguishedname;"msWMI-ChangeDate" = $msWMICreationDate; "msWMI-CreationDate" = $msWMICreationDate} 
    $WMIPath = ("CN=SOM,CN=WMIPolicy,CN=System,"+$ADdomain.DistinguishedName)
    if(-not ($WMIFilters.name -contains $msWMIName)){
        New-ADObject -name $WMICN -type "msWMI-Som" -Path $WMIPath -OtherAttributes $Attr -WhatIf: $check_mode
        $result.changed = $true
    }
    else{
        $Msg = "WMI Filter not imported: WMI Filter at $mof_file already exists"
        $result.changed = $false
    }
}
catch{
    $Msg = $_.Exception.ToString()
    Fail-Json $result "$mof_file could not be imported. Error was: $Msg"
    $result.changed = $false
}
Exit-Json -obj $result
