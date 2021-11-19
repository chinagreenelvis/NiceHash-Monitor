# NiceHash-Monitor
Automaton for miners using gaming or workstation rigs.

...

This [AutoHotKey](https://www.autohotkey.com/) script will automate the [NiceHash Miner](https://www.nicehash.com) and switch between [AfterBurner profiles](https://www.msi.com/Landing/afterburner/graphics-cards) for users who wish to game or use other GPU-intensive software on the same rig. It will automatically detect programs listed in the INI file, or programs launched from directories listed in the INI file, and start/stop the mining/overclocking process.

Currently only works with the NiceHash Miner (not QuickMiner). Works best when the miner and AfterBurner are set to run in the system tray.

The AfterBurner profile switching can be enabled or disabled in the INI file. The INI file will be created on startup and can be accessed by right-clicking on the system tray icon. By default, Profile 1 is set for non-mining and Profile 2 is set for mining.

To add programs to the monitoring list, put them under [Programs] in the INI:
```
[Programs]  
Program1.exe  
Program2.exe  
```
To add directories to the monitoring list, put them under [ProgramDirs]:
```
[ProgramDirs]  
G:\Games  
C:\Some Other Folder
```
Any program launched from the listed directory (and its sub-directories) will trigger the automated switching. When no programs from the listed directories are running, mining (and overclocking, if enabled) will be restored. You can manually switch between modes by right-clicking the system tray icon.
