# Temporarily disable PowerPlan settings

When processing data for long time your Computer might go into hibernation or shut down depending on your power settings. Same for closing the Lid on a Laptop. This code can temporarily disable PowerPlan settings while the script is running.

Laptops can switch and hide PowerPlans when plugged in or in battery mode that's why all PowerPlans can be adjusted at once to avoid unecpected behavior when unplugging. PowerCFG adjusts settings per plan not all PowerPlans at once. If disabling hibernation on the current active PowerPlan on a Laptop and then unplugging it, your Laptop might still go into hibernation on the battery plan and cancel your processing.

#### Some additional notes

- PowerCFG does not list hidden plans but can edit them. CIM/WIM can neither list or edit them.
- PowerCFG allows for individual Plan editing which causes confusion since computers can switch PowerPlans automatic.
- Windows user interface PowerButton and Lid close actions are applied to all Powerplans not individually.
- PowerCFG can randomly be incredibly slow and take around 3sec to spit out a response. I didn't figure out what can cause it and only a reboot seemed to fix it.
- PowerPlans are on purpose collected via the Registry directly since PowerCFG and CIM/WIM do not list hidden Plans.
- The Verbose version of the script is checking via WMI if a Laptop is plugged in because the CIM alternative is (suprisingly) about 5x slower in this case.

#### Disclaimer

The scripts works fine on my Win10 ROG Laptop. I cannot tell or know how other Windows versions might need some adjusting. You might have to edit the Registry location or change the string handling yourself.
