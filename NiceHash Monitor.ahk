; NiceHash Monitor
; by chinagreenelvis
; Version 0.1
 
#NoEnv
#SingleInstance force
#Persistent
SetWorkingDir %A_ScriptDir%
DetectHiddenWindows, On
SetTitleMatchMode, 1

Global UserProfile
EnvGet, UserProfile, USERPROFILE

Global RunningPrograms := []

Global INIFile := "NiceHashMonitor.ini"

Global NiceHashLocation
Global HideIcon := 0
Global TimerLength := 5000
Global OverClockCommandsEnabled := 1

ReadINI()
{
	IfNotExist, %INIFile%
{
INIText =
(
[Settings]
[Programs]
[ProgramDirs]
[OverClock]
)
FileAppend, %INIText%, %INIFile%
}

	SetINI("NiceHashLocation", INIFile, "Settings", "NiceHashLocation", USERPROFILE "\AppData\Local\Programs\NiceHash Miner\NiceHashMiner.exe")
	SetINI("HideIcon", INIFile, "Settings", "HideIcon", HideIcon)
	SetINI("TimerLength", INIFile, "Settings", "TimerLength", TimerLength)
	SetINI("OverClockCommandsEnabled", INIFile, "OverClock", "OverClockCommandsEnabled", OverClockCommandsEnabled)
	SetINI("OverClockOnCommand", INIFile, "OverClock", "OverClockOnCommand", "C:\Program Files (x86)\MSI Afterburner\MSIAfterburner.exe -Profile2")
	SetINI("OverClockOffCommand", INIFile, "OverClock", "OverClockOffCommand", "C:\Program Files (x86)\MSI Afterburner\MSIAfterburner.exe -Profile1")
}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; MENU

Menu, Tray, NoStandard
Menu, Tray, NoDefault
Menu, Tray, Add, Hide Icon, MenuHideIcon
Menu, Tray, Add, Open INI, MenuOpenINI
Menu, Tray, Add, Start NiceHash, MenuStart
Menu, Tray, Add, Stop NiceHash, MenuStop
Menu, Tray, Add, Auto NiceHash, MenuAuto
Menu, Tray, Add, Quit NiceHash Monitor, MenuQuit

MenuHideIcon()
{
	IniWrite, 1, %INIFile%, Settings, HideIcon
	ReadINI()
}

MenuOpenINI()
{
	Run, %INIFile%
}

MenuStart()
{
	SetTimer, RunTimer, Delete
	MinerStart()
}

MenuStop()
{
	SetTimer, RunTimer, Delete
	MinerClose()
}

MenuAuto()
{
	ReadINI()
	SetTimer, RunTimer, %TimerLength%
}

MenuQuit()
{
	ExitApp
}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; TEST



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; START

WMI := ComObjGet("winmgmts:")
ComObjConnect(createSink := ComObjCreate("WbemScripting.SWbemSink"), EventSink)
WMI.ExecNotificationQueryAsync(createSink, "select * from __InstanceCreationEvent Within 1 Where TargetInstance ISA 'Win32_Process'")

SetTimer, RunTimer, %TimerLength%

Return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; STANDARD FUNCTIONS

ProcessExist(Name)
{
	Process, Exist, %Name%
	return Errorlevel
}

SetINI(OutPutVar, FileName, Section, Key, DefaultSetting := 0)
{
	IniRead, %OutPutVar%, %FileName%, %Section%, %Key%
	If %OutPutVar% = ERROR
	{
		;MsgBox, That key does not exist in %FileName%, %Section%, %Key%
		IniWrite, %DefaultSetting%, %FileName%, %Section%, %Key%
		IniRead, %OutPutVar%, %FileName%, %Section%, %Key%
	}
}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; CUSTOM FUNCTIONS

;; LAUNCHED PROCESS
;; provided by teadrinker https://www.autohotkey.com/boards/viewtopic.php?f=76&t=96818&p=430272#p430272

class EventSink
{
   OnObjectReady(obj) {
	 
			NewProcess := GetProcessImageName(obj.TargetInstance.ProcessID)
      ;MsgBox %NewProcess%
			SplitPath, NewProcess, ProgramFileName, ProgramFileDir
			;MsgBox, %ProgramFileDir% %ProgramFileName%
			
			IniRead, Programs, %INIFile%, Programs
			Loop, Parse, Programs, `n
			{
				;MsgBox, %A_LoopField%
				;MsgBox, %ProgramFileName%
				If ProgramFileName contains %A_LoopField%
				{
					RunningPrograms.Push(ProgramFileName)
					MsgBox %ProgramFileName%
				}
			}
			
			IniRead, ProgramDirs, %INIFile%, ProgramDirs
			Loop, Parse, ProgramDirs, `n
			{
				If ProgramFileDir contains %A_LoopField%
				{
					;MsgBox %ProgramFileName%
					RunningPrograms.Push(ProgramFileName)
				}
			}
   }
}

GetProcessImageName(PID) {
   static access := PROCESS_QUERY_INFORMATION := 0x400
   if !hProc := DllCall("OpenProcess", "UInt", access, "Int", 0, "UInt", PID, "Ptr")
      throw "Failed to open process, error: " . A_LastError
   VarSetCapacity(imagePath, 1024, 0)
   DllCall("QueryFullProcessImageName", "Ptr", hProc, "UInt", 0, "Str", imagePath, "UIntP", 512)
   DllCall("CloseHandle", "Ptr", hProc)
   Return imagePath
}

MinerClose()
{
	If (ProcessExist("app_nhm.exe"))
	{
		;MsgBox, Closing NiceHash Miner
		WinClose, NiceHash Miner ahk_exe app_nhm.exe
		WinWaitClose, NiceHash Miner ahk_exe app_nhm.exe
		If (OverClockCommandsEnabled)
		{
			Run, %OverClockOffCommand%
		}
	}
}

MinerStart()
{
	If (!ProcessExist("app_nhm.exe"))
	{
		;MsgBox, Starting NiceHash Miner
		IniRead, NiceHashLocation, %INIFile%, Settings, NiceHashLocation
		Run, %NiceHashLocation%
		WinWait, NiceHash Miner ahk_exe app_nhm.exe
		WinMinimize, NiceHash Miner ahk_exe app_nhm.exe
		If (OverClockCommandsEnabled)
		{
			Run, %OverClockOnCommand%
		}
	}
}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; TIMERS

RunTimer:

	ReadINI()
	
	If (HideIcon)
		Menu, Tray, NoIcon
	Else
		Menu, Tray, Icon
	
	ProcessRunning := 0
	
	Loop % RunningPrograms.Length()
	{
		;MsgBox, % RunningPrograms[A_Index]
		If (ProcessExist(RunningPrograms[A_Index]))
		{
			;MsgBox, ProcessExist
			ProcessRunning := 1
		}
		Else
		{
			RunningPrograms.Delete(A_Index)
		}
	}
	
	If (ProcessRunning)
	{
		;MsgBox, ProcessRunning
		MinerClose()
	}
	Else
	{
		;MsgBox, !ProcessRunning
		MinerStart()
	}

Return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; HOTKEYS


