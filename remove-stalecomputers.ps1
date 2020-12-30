param (
    [Parameter(Mandatory=$true)]
    [int]$daysBeforeDelete = 60,
    [Parameter(Mandatory=$true)]
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
    $disabledLogData = @()
    $deletedLogData = @()

    try {
        New-EventLog -Source $disableSource -LogName "Application" -ErrorAction Stop
        New-EventLog -Source $deleteSource -LogName "Application" -ErrorAction Stop
    }
    # This catch is in place to prevent errors if the source already exists
    catch [System.InvalidOperationException] {}
}

$currentDate = Get-Date
$disableDate = $currentDate.AddDays(-($daysBeforeDisable))
$deleteDate = $currentDate.AddDays(-($daysBeforeDelete))
$computerList = Get-ADComputer -Filter ('name -like "*"') -SearchBase $searchBaseDn -SearchScope Subtree

foreach ($computer in $computerList) {
    if ($computer.LastLogonDate -le $disableDate -and $computer.Enabled -eq "True") {
        $computer | Set-ADComputer -Enabled $false
        if ($enableLogging) {
            $disabledLogData = $disabledLogData + "$($computer.name) - $($computer.LastLogonDate) - Disabled Object"
        }
    }
    if ($computer.LastLogonDate -le $deleteDate -and $computer.Enabled -eq "False") {
        $computer | Remove-ADComputer -Confirm:$false
        if ($enableLogging) {
            $deletedLogData = $deletedLogData + "$($computer.name) - $($computer.LastLogonDate) - Deleted Object"
        }
    }
}

if ($enableLogging) {
    Write-EventLog -LogName Application -Source $disableSource -EntryType Information `
        -Message $disabledLogData -EventId $disableObjectsEventId

    Write-EventLog -LogName Application -Source $deleteSource -EntryType Information `
        -Message $deletedLogData -EventId $deleteObjectsEventId
}