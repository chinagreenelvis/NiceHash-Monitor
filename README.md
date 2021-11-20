# NiceHash-Monitor
This [AutoHotKey](https://www.autohotkey.com/) script will automate the [NiceHash Miner](https://www.nicehash.com) and switch between [AfterBurner profiles](https://www.msi.com/Landing/afterburner/graphics-cards) for users who wish to game or use other GPU-intensive software on the same rig by monitoring competing processes. It works with both NiceHash Miner and NiceHash QuickMiner (fully installed clients only). Results are best when the apps are set to run in the system tray. Miner installation locations can be configured in the INI. The INI file will be created on startup and can be accessed by right-clicking on the system tray icon.

To add specific processes to the monitoring list, put them under [Programs] in the INI:
```
[Programs]  
Program_Name_Without_Path.exe  
Another_Program_Name_Without_Path.exe  
```
To add entire directories to the monitoring list, put them under [ProgramDirs]. For example:
```
[ProgramDirs]  
G:\Games  
C:\Program Files (x86)\Steam\steamapps\common  
```
When NiceHash Monitor detects running programs that are listed (or whose paths include any of the listed directories), it will stop the mining application and automatically switch to the non-overclocking profile listed in the INI file (Profile1 by default). (In the above example, any program that resides in any folder under G:\Games will shut down the mining process, as will any program or game on the Steam platform.)  
  
When none of the listed programs or programs that reside in the listed directories are running, the mining application will be restarted and the overclocking profile (Profile2 by default) will be reinstated. The INI file contains the option to enable/disable Afterburner profile switching. You can manually switch between modes (on/off/auto) by right-clicking the system tray icon.

...

Revision History

0.01 - Initial Release  
0.02 - Bugfixes, updated to work with both miner and quickminer.  
0.03 - More reliable code; removed timer mechanism and added full check of running processes at application start, process execution, and process termination. Added -q parameter to AfterBurner commands which will prevent AfterBurner from staying in the system tray if it is not already loaded. (Deletion of old INI file recommended.) Added better window-minimization code for miner.  
0.04 - Bugfixes with minimizing and manual mode-switching. Added minimization setting to INI (does not apply to QuickMiner).
