# RemoveStaleAdComputes
Removes and disables AD objects older than X number of days.

## Parameters

The default values for these parameters is just a starting point. You should refer to your company policy on age of objects and modify accordingly.

### daysBeforeDelete

This parameter will specify the number of days before a delete action occurs.

Default Value = 60

### daysBeforeDisable

This parameter will specify the number of days before the computer object is disabled.

Default Value = 45

### enableLogging

This is a switch parameter. When enabled, the script will log the actions to the windows event log from where the script is being run. This will create the following:

Event Source: "Disable-ComputerObject"
Event Source: "Delete-Computerobject"

A query can be run against both of these sources within the windows event log to get the details on which machines were disabled/deleted and when their last logon was.

### searchBaseDn

By default this script will query the entire domain for computer objects. If you wish to run this against specific OU, use this parameter and supply the DN of the OU of which to run against.

This is useful to run against servers vs workstations and/or have different settings on expire dates for each.

## Examples

Run the script providing values for when to disable and when to delete. This example also enables the logging abilities.

```powershell
.\remove-stalecomputers.ps1 -daysBeforeDelete 90 -daysBeforeDisable 60 -enableLogging
```

Basic script run using all default values

```powershell
.\remove-stalecomputers.ps1
```

Run the script providing a specifc OU to run against

```powershell
.\remove-stalecomputers.ps1 -searchBaseDn "OU=Workstations,OU=Computers,DC=domain,DC=local"
```
