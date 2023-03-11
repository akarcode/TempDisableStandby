Clear-Host

# Lid: DoNothing (0), Sleep (1), Hibernate (2), ShutDown (3)
$DisableLid = 0

# get active powerplan
$ActiveGUID = (PowerCFG -GETACTIVESCHEME).split(' ')[3]

# get powerplans from registry
$RegistryHive = [Microsoft.Win32.RegistryHive]::LocalMachine
$RegistryView = [Microsoft.Win32.RegistryView]::Default
$SubKey = 'SYSTEM\CurrentControlSet\Control\Power\User\PowerSchemes\'
$PowerPlans = [Microsoft.Win32.RegistryKey]::OpenBaseKey($RegistryHive, $RegistryView).OpenSubKey($SubKey).GetSubKeyNames()

# unhide lid settings
PowerCFG -ATTRIBUTES SUB_BUTTONS LIDACTION -ATTRIB_HIDE

# grab existing settings and set temporal value
$ExistingSettings = @{}
foreach ($Plan in $PowerPlans) {

    $CheckSetting = PowerCFG -QUERY $Plan SUB_BUTTONS LIDACTION

    [array]$ExistingSettings[$Plan] += [UInt32]($CheckSetting[-3] -split (': '))[1]
    [array]$ExistingSettings[$Plan] += [UInt32]($CheckSetting[-2] -split (': '))[1]

    PowerCFG -SETACVALUEINDEX $Plan SUB_BUTTONS LIDACTION $DisableLid
    PowerCFG -SETDCVALUEINDEX $Plan SUB_BUTTONS LIDACTION $DisableLid
    PowerCFG -SETACTIVE $Plan
}
PowerCFG -SETACTIVE $ActiveGUID

############# DO SOMETHING HERE #############'

# reinstate settings
foreach ($Plan in $PowerPlans) {
    
    PowerCFG -SETACVALUEINDEX $Plan SUB_BUTTONS LIDACTION $ExistingSettings[$Plan][0]
    PowerCFG -SETDCVALUEINDEX $Plan SUB_BUTTONS LIDACTION $ExistingSettings[$Plan][1]
    PowerCFG -SETACTIVE $Plan
}
PowerCFG -SETACTIVE $ActiveGUID

Write-Host 'Done!'