Clear-Host

# Lid: DoNothing (0), Sleep (1), Hibernate (2), ShutDown (3)
$ProcessingSettings = @{ Hibernate = 0; Harddisk = 0; Lid = 0; Sleep = 0; Display = 2 }

foreach ( $Setting in $ProcessingSettings.GetEnumerator() | Where-Object { $_.Name -ne 'Lid' }) { $ProcessingSettings[$Setting.Name] *= 60 }

# get active powerplan
$ActiveGUID = (PowerCFG -GETACTIVESCHEME).split(' ')[3]

# get powerplans from registry
$RegistryHive = [Microsoft.Win32.RegistryHive]::LocalMachine
$RegistryView = [Microsoft.Win32.RegistryView]::Default
$SubKey = 'SYSTEM\CurrentControlSet\Control\Power\User\PowerSchemes\'
$RegistryPlans = [Microsoft.Win32.RegistryKey]::OpenBaseKey($RegistryHive, $RegistryView).OpenSubKey($SubKey).GetSubKeyNames()

$AvailablePlans = @{}
foreach ($Plan in $RegistryPlans) {

    $TempName = ([Microsoft.Win32.RegistryKey]::OpenBaseKey($RegistryHive, $RegistryView).OpenSubKey(($SubKey + $Plan + '\')).GetValue('FriendlyName')).split(',')[-1].split('(')[0].Trim()

    $AvailablePlans[$TempName] = $Plan

}

# set aliases per setting
$AllSettings = @{ Sleep = 'SUB_SLEEP', 'STANDBYIDLE'; Display = 'SUB_VIDEO', 'VIDEOIDLE'; Hibernate = 'SUB_SLEEP', 'HIBERNATEIDLE'; Harddisk = 'SUB_DISK', 'DISKIDLE'; Lid = 'SUB_BUTTONS', 'LIDACTION' }

# unhide lid settings
PowerCFG -ATTRIBUTES SUB_BUTTONS LIDACTION -ATTRIB_HIDE

# grab existing settings and set temporal value
$ExistingSettings = @{}
foreach ($Plan in $AvailablePlans.GetEnumerator()) {
    
    $ExistingSettings[$Plan.Name] = @{}

    foreach ($Setting in $AllSettings.GetEnumerator()) {

        $CheckSetting = PowerCFG -QUERY $Plan.Value $Setting.Value[0] $Setting.Value[1]

        [array]$ExistingSettings[$Plan.Name][$Setting.Name] += [UInt32]($CheckSetting[-3] -split (': '))[1]
        [array]$ExistingSettings[$Plan.Name][$Setting.Name] += [UInt32]($CheckSetting[-2] -split (': '))[1]

        PowerCFG -SETACVALUEINDEX $Plan.Value $Setting.Value[0] $Setting.Value[1] ($ProcessingSettings[$Setting.Name])
        PowerCFG -SETDCVALUEINDEX $Plan.Value $Setting.Value[0] $Setting.Value[1] ($ProcessingSettings[$Setting.Name])

    }
    PowerCFG -SETACTIVE $Plan.Value
}
PowerCFG -SETACTIVE $ActiveGUID

############# DO SOMETHING HERE #############'

# reinstate settings
foreach ($Plan in $AvailablePlans.GetEnumerator()) {
    
    foreach ($Setting in $AllSettings.GetEnumerator()) {

        PowerCFG -SETACVALUEINDEX $Plan.Value $Setting.Value[0] $Setting.Value[1] ($ExistingSettings[$Plan.Name][$Setting.Name][0])
        PowerCFG -SETDCVALUEINDEX $Plan.Value $Setting.Value[0] $Setting.Value[1] ($ExistingSettings[$Plan.Name][$Setting.Name][1])

    }
    PowerCFG -SETACTIVE $Plan.Value
}
PowerCFG -SETACTIVE $ActiveGUID

Write-Host 'Done!'
