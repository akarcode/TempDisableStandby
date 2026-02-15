
Function Disable-Standby {

    param (
        
        [Parameter(Mandatory=$True)][string]$PathSettings,
        [Parameter(Mandatory=$False)][switch]$Reinstate
        
    )

    $PathSettings = ($PathSettings + 'PowerPlan_Settings.xml')


    if (!$Reinstate) {

        # Timings are in seconds except for the Lid
        # Lid: DoNothing (0), Sleep (1), Hibernate (2), ShutDown (3)
        $Settings = @{
            Categories = @{
                Hibernate = 0, 'SUB_SLEEP', 'HIBERNATEIDLE';
                Harddisk  = 0, 'SUB_DISK', 'DISKIDLE';
                Lid       = 0, 'SUB_BUTTONS', 'LIDACTION';
                Sleep     = 0, 'SUB_SLEEP', 'STANDBYIDLE';
                Display   = 2, 'SUB_VIDEO', 'VIDEOIDLE'
            }; Plans   = @{} 
        }

        foreach ( $Item in $Settings.Categories.GetEnumerator() | Where-Object { $_.Name -ne 'Lid' }) {
        
            $Settings.Categories[$Item.Name][0] *= 60
            
        }

        # get active powerplan
        $Settings.ActiveGUID = (PowerCFG -GETACTIVESCHEME).split(' ')[3]

        # get powerplans from registry
        $RegistryHive = [Microsoft.Win32.RegistryHive]::LocalMachine
        $RegistryView = [Microsoft.Win32.RegistryView]::Default
        $SubKey = 'SYSTEM\CurrentControlSet\Control\Power\User\PowerSchemes\'
        $RegistryPlans = [Microsoft.Win32.RegistryKey]::OpenBaseKey($RegistryHive, $RegistryView).
            OpenSubKey($SubKey).
            GetSubKeyNames()

        foreach ($Plan in $RegistryPlans) {
        
            $PlanKey = [Microsoft.Win32.RegistryKey]::OpenBaseKey($RegistryHive, $RegistryView).
                OpenSubKey($SubKey + $Plan + '\')

            # skip overlays and ghost entries with a SUB_SLEEP subkey check
            if ($PlanKey.GetSubKeyNames() -notcontains '238c9fa8-0aad-41ed-83f4-97be242c8f20') { continue }
        
            $TempName = ([Microsoft.Win32.RegistryKey]::OpenBaseKey($RegistryHive, $RegistryView).
                OpenSubKey(($SubKey + $Plan + '\')).
                GetValue('FriendlyName')).
                Split(',')[-1].
                Split('(')[0].
                Trim()

            $Settings.Plans[$TempName] = @{ GUID = $Plan; Time = @{}}

        }

        # unhide lid settings
        PowerCFG -ATTRIBUTES SUB_BUTTONS LIDACTION -ATTRIB_HIDE

        if (Test-Path -Path $PathSettings) {
            
            Write-Host -Text 'Existing settings file found!' -Color 'Black'

            $Settings = Import-Clixml -Path $PathSettings

            # check if settings are temporal value already or else set it
            foreach ($Plan in $Settings.Plans.GetEnumerator()) {

                foreach ($Property in $Settings.Categories.GetEnumerator()) {

                    $CheckSetting = PowerCFG -QUERY $Plan.Value.GUID $Property.Value[1] $Property.Value[2]

                    $AcLine = $CheckSetting | Where-Object { $_ -match 'Current AC Power Setting Index' }
                    $DcLine = $CheckSetting | Where-Object { $_ -match 'Current DC Power Setting Index' }

                    if (([UInt32]($AcLine -split ': ')[1].Trim(), [UInt32]($DcLine -split ': ')[1].Trim()) -notcontains $Settings.Categories[$Property.Name][0]) {

                        foreach ($Iteration in $True, $False) {

                            $PowerType = if ($Iteration) { '-SETACVALUEINDEX' } else { '-SETDCVALUEINDEX' }

                            PowerCFG $PowerType $Plan.Value.GUID $Property.Value[1] $Property.Value[2] $Settings.Categories[$Property.Name][0]
                        }
                    }
                }
                PowerCFG -SETACTIVE $Plan.Value.GUID
            } 
            PowerCFG -SETACTIVE $Settings.ActiveGUID

        } else {

            # grab existing settings and set temporal value
            foreach ($Plan in $Settings.Plans.GetEnumerator()) {

                foreach ($Property in $Settings.Categories.GetEnumerator()) {
            
                    $CheckSetting = PowerCFG -QUERY $Plan.Value.GUID $Property.Value[1] $Property.Value[2]

                    $AcLine = $CheckSetting | Where-Object { $_ -match 'Current AC Power Setting Index' }
                    $DcLine = $CheckSetting | Where-Object { $_ -match 'Current DC Power Setting Index' }

                    $Settings.Plans[$Plan.Name].Time[$Property.Name] = @(

                        [UInt32]($AcLine -split ': ')[1].Trim(), [UInt32]($DcLine -split ': ')[1].Trim()

                    )

                    foreach ($Iteration in $True, $False) {

                        $PowerType = if ($Iteration) { '-SETACVALUEINDEX' } else { '-SETDCVALUEINDEX' }

                        PowerCFG $PowerType $Plan.Value.GUID $Property.Value[1] $Property.Value[2] $Settings.Categories[$Property.Name][0]

                    }

                }
                PowerCFG -SETACTIVE $Plan.Value.GUID
            }
            PowerCFG -SETACTIVE $Settings.ActiveGUID

            # exporting settings
            $Settings | Export-Clixml -Path $PathSettings

        }
    } else {

        $Settings = Import-Clixml -Path $PathSettings

        foreach ($Plan in $Settings.Plans.GetEnumerator()) {
    
            foreach ($Property in $Settings.Categories.GetEnumerator()) {

                foreach ($Index in 0, 1) {

                    $PowerType = if ($Index -eq 0) { '-SETACVALUEINDEX' } else { '-SETDCVALUEINDEX' }

                    PowerCFG $PowerType $Plan.Value.GUID $Property.Value[1] $Property.Value[2] $Settings.Plans[$Plan.Name].Time[$Property.Name][$Index]

                }
            }
            PowerCFG -SETACTIVE $Plan.Value.GUID
        }
        PowerCFG -SETACTIVE $Settings.ActiveGUID

        # delete settings file
        if (Test-Path -Path $PathSettings) {

            Remove-Item -Path $PathSettings

        }
    }
}


$PathSettings = 'C:\Folder\'
Disable-Standby -PathSettings $PathSettings

# do something
PAUSE

Disable-Standby -PathSettings $PathSettings -Reinstate

