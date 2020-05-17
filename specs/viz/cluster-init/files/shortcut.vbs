'Set objShell = WScript.CreateObject("WScript.Shell")
 
'Set sc = objShell.CreateShortcut(desktop & "paraview-5.7.0.lnk")
'sc.TargetPath = "C:\Program Files\ParaView-5.7.0-Windows-Python3.7-msvc2015-64bit\bin\paraview.exe"
'sc.WorkingDirectory = desktop

Set objWshShell = WScript.CreateObject("WScript.Shell")
strDesktopPath = objWshShell.SpecialFolders("Desktop")

Set objShortcut = objWshShell.CreateShortcut(strDesktopPath & "\paraview-5.7.0.lnk")
objShortcut.TargetPath = "C:\Program Files\ParaView-5.7.0-Windows-Python3.7-msvc2015-64bit\bin\paraview.exe"
objShortcut.Save
