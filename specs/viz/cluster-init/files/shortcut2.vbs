'Set objShell = WScript.CreateObject("WScript.Shell")
'Set sc = objShell.CreateShortcut(desktop & "vmd1.9.3.lnk")
'sc.TargetPath = "C:\Program Files (x86)\University of Illinois\VMD\vmd.exe"
'sc.WorkingDirectory = desktop
'sc.save

Set objWshShell = WScript.CreateObject("WScript.Shell")
strDesktopPath = objWshShell.SpecialFolders("Desktop")
Set objShortcut = objWshShell.CreateShortcut(strDesktopPath & "\vmd1.9.3.lnk")
objShortcut.TargetPath = "C:\Program Files (x86)\University of Illinois\VMD\vmd.exe"
objShortcut.Save
