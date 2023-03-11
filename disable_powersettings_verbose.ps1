Clear-Host

# in minutes
$ProcessingSettings = @{

    Hibernate = 0;
    Harddisk = 0;
    Lid = 0; # DoNothing (0), Sleep (1), Hibernate (2), ShutDown (3)
    Sleep = 0;
    Display = 2;

}

foreach ( $Setting in $ProcessingSettings.GetEnumerator() | Where-Object { $_.Name -ne 'Lid' }) {
    
    $ProcessingSettings[$Setting.Name] *= 60

}

Function Get-Registry {

    Param(
        
        [switch]$All,
        [string]$PowerPlan

    )

    $RegistryHive = [Microsoft.Win32.RegistryHive]::LocalMachine
    $RegistryView = [Microsoft.Win32.RegistryView]::Default
    $SubKey = 'SYSTEM\CurrentControlSet\Control\Power\User\PowerSchemes\'

    if ($All) {

        [Microsoft.Win32.RegistryKey]::OpenBaseKey($RegistryHive, $RegistryView).OpenSubKey($SubKey).GetSubKeyNames()

    } else {

        $SubKey = ($SubKey + $PowerPlan + '\')

        ([Microsoft.Win32.RegistryKey]::OpenBaseKey($RegistryHive, $RegistryView).OpenSubKey($SubKey).GetValue('FriendlyName')).split(',')[-1].split('(')[0].Trim()

    }
}


# check if laptop is plugged in
if ([bool](Get-WMIObject -Class BatteryStatus -Namespace ROOT\WMI -ComputerName 'localhost').PowerOnline) {
    
    Write-Host 'Laptop is plugged in'

} else {

    Write-Host 'Laptop is unplugged'

}
Write-Host '---------------------'


# collect powerplans and list them
$TempPlans = PowerCFG -LIST

$VisiblePlans = @{}
foreach ($Plan in $TempPlans | Where-Object { $_ -Match '^Power' }) {

    $TempGUID = $Plan.split(' ')[3]
    $TempName = $Plan.split('()')[1]

    $VisiblePlans[$TempName] = $TempGUID

    if ($Plan -Match '\*$') {
        
        $ActiveGUID = $TempGUID
    
    }
}

$RegistryPlans = Get-Registry -All

Write-Host 'Available Power plan(s):'
Write-Host '(* is active, # is hidden)'
Write-Host '---------------------'

$AvailablePlans = @{}
foreach ($Plan in $RegistryPlans) {

    $TempName = Get-Registry -PowerPlan $Plan

    $AvailablePlans[$TempName] = $Plan

    if ($Plan -eq $ActiveGUID) {

        Write-Host ('* ' + $TempName)

    } elseif ($VisiblePlans.Keys -NotContains $TempName) { 
        
        Write-Host ('# ' + $TempName)
        
    } else {

        Write-Host ('  ' + $TempName)

    }
}


Write-Host '---------------------'
Write-Host 'Collect Current PowerPlan Settings.'
Write-Host 'And set temp values after...'

$AllSettings = @{

        Sleep = 'SUB_SLEEP', 'STANDBYIDLE'
        Display = 'SUB_VIDEO', 'VIDEOIDLE'
        Hibernate = 'SUB_SLEEP', 'HIBERNATEIDLE'
        Harddisk = 'SUB_DISK', 'DISKIDLE'
        Lid = 'SUB_BUTTONS', 'LIDACTION'

}

# unhide lid action
PowerCFG -ATTRIBUTES SUB_BUTTONS LIDACTION -ATTRIB_HIDE

# grab existing settings and set temporal value
$ExistingSettings = @{}
foreach ($Plan in $AvailablePlans.GetEnumerator()) {
    
    $ExistingSettings[$Plan.Name] = @{}

    foreach ($Setting in $AllSettings.GetEnumerator()) {

        $CheckSetting = PowerCFG -QUERY $Plan.Value $Setting.Value[0] $Setting.Value[1]

        $TempAC = [UInt32]($CheckSetting[-3] -split (': '))[1]
        $TempDC = [UInt32]($CheckSetting[-2] -split (': '))[1]

        [array]$ExistingSettings[$Plan.Name][$Setting.Name] += $TempAC
        [array]$ExistingSettings[$Plan.Name][$Setting.Name] += $TempDC

        PowerCFG -SETACVALUEINDEX $Plan.Value $Setting.Value[0] $Setting.Value[1] ($ProcessingSettings[$Setting.Name])
        PowerCFG -SETDCVALUEINDEX $Plan.Value $Setting.Value[0] $Setting.Value[1] ($ProcessingSettings[$Setting.Name])

    }

    PowerCFG -SETACTIVE $Plan.Value

}

PowerCFG -SETACTIVE $ActiveGUID


Write-Host '---------------------'
Write-Host '#############################################'
Write-Host '############# DO SOMETHING HERE #############'
Write-Host '#############################################'


Write-Host '---------------------'
Write-Host 'Reinstating the previous settings...'

foreach ($Plan in $AvailablePlans.GetEnumerator()) {
    
    foreach ($Setting in $AllSettings.GetEnumerator()) {

        PowerCFG -SETACVALUEINDEX $Plan.Value $Setting.Value[0] $Setting.Value[1] ($ExistingSettings[$Plan.Name][$Setting.Name][0])
        PowerCFG -SETDCVALUEINDEX $Plan.Value $Setting.Value[0] $Setting.Value[1] ($ExistingSettings[$Plan.Name][$Setting.Name][1])

    }

    PowerCFG -SETACTIVE $Plan.Value

}

PowerCFG -SETACTIVE $ActiveGUID

Write-Host 'Done!'
