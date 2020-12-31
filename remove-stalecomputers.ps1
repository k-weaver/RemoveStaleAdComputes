param (
    [Parameter(Mandatory=$false)]
    [int]$daysBeforeDelete = 60,
    [Parameter(Mandatory=$false)]
    [int]$daysBeforeDisable = 45,
    [Parameter(Mandatory=$false)]
    [switch]$enableLogging,
    [Parameter(Mandatory=$false)]
    $searchBaseDn
)

try {
    Import-Module ActiveDirectory -ErrorAction Stop
}
catch {
    $Error[0]
    throw "Failed to import AD module, ensure RSAT is installed"
}

if (!($searchBaseDn)) {
    $searchBaseDn = (Get-ADDomain).DistinguishedName
}

if ($enableLogging) {
    $disableSource = "Disable-ComputerObject"
    $deleteSource = "Delete-ComputerObject"
    $disableObjectsEventId = 501
    $deleteObjectsEventId = 502
    [System.Collections.ArrayList]$disabledLogData = @()
    [System.Collections.ArrayList]$deletedLogData = @()

    try {
        New-EventLog -Source $disableSource -LogName "Application" -ErrorAction Stop
    }
    # This catch is in place to prevent errors if the source already exists
    catch [System.InvalidOperationException] {}
    try {
        New-EventLog -Source $deleteSource -LogName "Application" -ErrorAction Stop
    }
    # This catch is in place to prevent errors if the source already exists
    catch [System.InvalidOperationException] {}
}

$currentDate = Get-Date
$disableDate = $currentDate.AddDays(-($daysBeforeDisable))
$deleteDate = $currentDate.AddDays(-($daysBeforeDelete))
$computerList = Get-ADComputer -Filter ('name -like "*"') -SearchBase $searchBaseDn -SearchScope Subtree -Properties LastLogonDate

foreach ($computer in $computerList) {
    if ($computer.LastLogonDate -le $disableDate -and $computer.Enabled -eq "True") {
        $computer | Set-ADComputer -Enabled $false -WhatIf
        if ($enableLogging) {
            $disableValue = $null
            $disableValue = [pscustomobject]@{'objectName'=$computer.name;'timeStamp'=$computer.LastLogonDate;'action'="disabled"}
            $disabledLogData.Add($disableValue) | Out-Null
        }
    }
    if ($computer.LastLogonDate -le $deleteDate -and $computer.Enabled -eq $false) {
        $computer | Remove-ADComputer -Confirm:$false -WhatIf 
        if ($enableLogging) {
            $deletedValue = $null
            $deletedValue = [pscustomobject]@{'objectName'=$computer.name;'timeStamp'=$computer.LastLogonDate;'action'="deleted"}
            $deletedLogData.Add($deletedValue) | Out-Null
        }
    }
}

if ($enableLogging) {
    if ($disabledLogData.Count -eq 0) {
        $disabledMessage = "No objects to disable"
    }
    else {
        $disabledMessage = $disabledLogData | Out-String
    }
    if ($deletedLogData.Count -eq 0) {
        $deletedMessage = "No objects to delete"
    }
    else {
        $deletedMessage = $deletedLogData | Out-String
    }
    Write-EventLog -LogName Application -Source $disableSource -EntryType Information `
        -Message "$disabledMessage" -EventId $disableObjectsEventId

    Write-EventLog -LogName Application -Source $deleteSource -EntryType Information `
        -Message "$deletedMessage" -EventId $deleteObjectsEventId
}