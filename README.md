# Temporarily disable standby settings

When processing data for an extended period, your computer might hibernate or shut down based on your power settings. This can also occur when closing the lid on a laptop. The following PowerShell function temporarily adjusts your power plan settings to prevent this while your script is running.

On laptops, power plans can change or become hidden when switching between plugged-in and battery modes. To prevent unexpected behavior, it's important to adjust all power plans simultaneously. PowerCFG modifies settings for individual plans, not all plans at once. For example, if you disable hibernation on the current active power plan while plugged in, but then unplug the laptop, it might still hibernate due to the battery power plan, interrupting your processing.

You'll have to adjust the path where you want to temporally store the setting before running.

#### additional notes

- PowerCFG does not list hidden plans but can edit them. CIM/WIM can neither list or edit them.
- PowerCFG allows for individual Plan editing which causes confusion since computers can switch power plans automatic.
- Windows user interface PowerButton and Lid close actions are applied to all power plans not individually.
- PowerCFG can randomly be incredibly slow and take around 3sec to spit out a response. I didn't figure out what can cause it.
- Power plans are on purpose collected via the Registry directly since PowerCFG and CIM/WIM do not list hidden Plans.

## Legacy

These are the old versions of the script, they might still be useful for someone.

#### Versions

 - **Verbose** has a bunch of feedback added that are purely informative not functional.
 - **Minimized** reduced to a more barebones version which is easy to include in your own scripts. However also less readable since some parts are also reduced to one line.
 - **LidOnly** reduced to only adjust the LidClose Action.

#### additional legacy notes

- The Verbose version of the script is checking via WMI if a Laptop is plugged in because the CIM alternative is (suprisingly) about 5x slower in this case.

## Changelog

v1.0.1

- Wrapped the code into a function
- The settings are temp stored in a XML file

v1.0 (Initial release)

## Disclaimer

The scripts works fine on my Win10 ROG Laptop. I cannot tell or know how other Windows versions might need some adjusting.

