; NiceHash Monitor
; by chinagreenelvis
; Version 0.04

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

Global QuickMiner := 0
Global MinimizeMiner := 1
Global NiceHashMinerLocation
Global NiceHashQuickMinerLocation
Global HideIcon := 0
Global OverClockCommandsEnabled := 1
Global OverClockOnCommand
Global OverClockOffCommand

Global NiceHashExecutable
Global NiceHashWindow
Global NiceHashLocation
Global NiceHashLocationDir

Global AProcessIsRunning
Global AProcessWasRunning

Global EnableAuto := 1

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; SETTINGS

ReadINI()
{
	IfNotExist, %INIFile%
{
INIText =
(
[Settings]
[Programs]
[ProgramDirs]
[ExcludedPrograms]
[ExcludedProgramDirs]
[OverClock]
)
FileAppend, %INIText%, %INIFile%
}

	SetINI("QuickMiner", INIFile, "Settings", "QuickMiner", QuickMiner)
	SetINI("MinimizeMiner", INIFile, "Settings", "MinimizeMiner", MinimizeMiner)
	SetINI("NiceHashMinerLocation", INIFile, "Settings", "NiceHashMinerLocation", USERPROFILE "\AppData\Local\Programs\NiceHash Miner\NiceHashMiner.exe")
	SetINI("NiceHashQuickMinerLocation", INIFile, "Settings", "NiceHashQuickMinerLocation", "C:\NiceHash\NiceHash QuickMiner\NiceHashQuickMiner.exe")
	SetINI("HideIcon", INIFile, "Settings", "HideIcon", HideIcon)
	SetINI("OverClockCommandsEnabled", INIFile, "OverClock", "OverClockCommandsEnabled", OverClockCommandsEnabled)
	SetINI("OverClockOnCommand", INIFile, "OverClock", "OverClockOnCommand", "C:\Program Files (x86)\MSI Afterburner\MSIAfterburner.exe -Profile2 -q")
	SetINI("OverClockOffCommand", INIFile, "OverClock", "OverClockOffCommand", "C:\Program Files (x86)\MSI Afterburner\MSIAfterburner.exe -Profile1 -q")

	If (QuickMiner)
	{
		NiceHashExecutable := "NiceHashQuickMiner.exe"
		NiceHashWindow := "NiceHash QuickMiner"
		NiceHashLocation := NiceHashQuickMinerLocation
	}
	Else
	{
		NiceHashExecutable := "app_nhm.exe"
		NiceHashWindow := "NiceHash Miner"
		NiceHashLocation := NiceHashMinerLocation
	}

	SplitPath, NiceHashLocation, , NiceHashLocationDir
}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; MENU

Menu, Tray, NoStandard
Menu, Tray, NoDefault
Menu, Tray, Add, Hide Icon, MenuHideIcon
Menu, Tray, Add, Open INI, MenuOpenINI
Menu, Tray, Add, Force Start NiceHash, MenuStart
Menu, Tray, Add, Stop NiceHash, MenuStop
Menu, Tray, Add, Set NiceHash to Auto, MenuAuto
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
	AProcessIsRunning := NULL
	EnableAuto := 0
	MinerStart()
}

MenuStop()
{
	AProcessIsRunning := NULL
	EnableAuto := 0
	MinerStop()
}

MenuAuto()
{
	EnableAuto := 1
	CheckProcesses()
}

MenuQuit()
{
	ExitApp
}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; TEST



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; START

WMI := ComObjGet("winmgmts:")
ComObjConnect(createSink := ComObjCreate("WbemScripting.SWbemSink"), EventSinkCreate)
ComObjConnect(deleteSink := ComObjCreate("WbemScripting.SWbemSink"), EventSinkDelete)
WMI.ExecNotificationQueryAsync(createSink, "select * from __InstanceCreationEvent Within 1 Where TargetInstance ISA 'Win32_Process'")
WMI.ExecNotificationQueryAsync(deleteSink, "select * from __InstanceDeletionEvent Within 1 Where TargetInstance ISA 'Win32_Process'")

ReadINI()
CheckProcesses()

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

;; PROCESS MONITOR
;; help provided by teadrinker https://www.autohotkey.com/boards/viewtopic.php?f=76&t=96818&p=430272#p430272

class EventSinkCreate
{
  OnObjectReady(obj)
	{
		If (EnableAuto)
		{
			CheckProcesses()
		}
  }
}

class EventSinkDelete
{
	OnObjectReady(obj)
	{
		If (EnableAuto)
		{
			CheckProcesses()
		}
	}
}

CheckProcesses()
{
	AProcessWasRunning := AProcessIsRunning
	AProcessIsRunning := 0

	For Process in ComObjGet("winmgmts:").ExecQuery("Select * from Win32_Process")
	{
		If (ProcessStopsMining(Process))
		{
			AProcessIsRunning := 1
		}
	}

	If (EnableAuto) && (AProcessWasRunning != AProcessIsRunning)
	{
		If (!AProcessIsRunning)
		{
			MinerStart()
		}
		Else
		{
			MinerStop()
		}
	}
}

ProcessStopsMining(Process)
{
	ReadINI()
	ProcessName := Process.Name
	;MsgBox, % ProcessName
	ProcessImageName := GetProcessImageName(Process.ProcessID)
	If (ProcessImageName)
	{
		if (IsExcludedProcess(ProcessName, ProcessImageName))
		{
			return False
		}

		;MsgBox, % ProcessImageName
		IniRead, Programs, %INIFile%, Programs
		Loop, Parse, Programs, `n
		{
			;MsgBox, %A_LoopField%
			If ProcessName contains %A_LoopField%
			{
				Return True
			}
		}

		IniRead, ProgramDirs, %INIFile%, ProgramDirs
		Loop, Parse, ProgramDirs, `n
		{
			;MsgBox, %A_LoopField%
			If ProcessImageName contains %A_LoopField%
			{
				Return True
			}
		}
	}
}

IsExcludedProcess(ProcessName, ProcessImageName)
{
	;MsgBox, % ProcessImageName
	IniRead, ExcludedPrograms, %INIFile%, ExcludedPrograms
	Loop, Parse, ExcludedPrograms, `n
	{
		;MsgBox, %A_LoopField%
		If ProcessName contains %A_LoopField%
		{
			Return True
		}
	}

	IniRead, ExcludedProgramDirs, %INIFile%, ExcludedProgramDirs
	Loop, Parse, ExcludedProgramDirs, `n
	{
		;MsgBox, %A_LoopField%
		If ProcessImageName contains %A_LoopField%
		{
			Return True
		}
	}
}

GetProcessImageName(PID)
{
	Static access := PROCESS_QUERY_INFORMATION := 0x400
	If !hProc := DllCall("OpenProcess", "UInt", access, "Int", 0, "UInt", PID, "Ptr")
	{
		Return
	}
	VarSetCapacity(ImagePath, 1024, 0)
	DllCall("QueryFullProcessImageName", "Ptr", hProc, "UInt", 0, "Str", ImagePath, "UIntP", 512)
	DllCall("CloseHandle", "Ptr", hProc)
	Return ImagePath
}

;; MINER CONTROL

MinerStart()
{
	ReadINI()
	If (!ProcessExist(NiceHashExecutable))
	{
		;MsgBox, Starting NiceHash Miner
		Run, %NiceHashLocation%, %NiceHashLocationDir%
		If (!QuickMiner && MinimizeMiner)
		{
			WaitForWindow:
			Loop
			{
				WinGet, WindowList, List, %NiceHashWindow% ahk_exe %NiceHashExecutable%
				Loop, %WindowList%
				{
					Window := % "ahk_id" . WindowList%A_Index%
					;MsgBox, %Window%
					WinGet, WindowStyle, Style, %Window%
					If (WindowStyle & 0x20000)
					{
						Sleep, 1000
						WinMinimize, %Window%
						Break WaitForWindow
					}
				}
			}
		}
	}
	If (OverClockCommandsEnabled)
	{
		Run, %OverClockOnCommand%
	}
}

MinerStop()
{
	ReadINI()
	If (ProcessExist(NiceHashExecutable))
	{
		;MsgBox, Closing NiceHash Miner
		WinClose, %NiceHashWindow% ahk_exe %NiceHashExecutable%
		WinWaitClose, %NiceHashWindow% ahk_exe %NiceHashExecutable%
	}
	If (OverClockCommandsEnabled)
	{
		Run, %OverClockOffCommand%
	}
}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; TIMERS



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; HOTKEYS


