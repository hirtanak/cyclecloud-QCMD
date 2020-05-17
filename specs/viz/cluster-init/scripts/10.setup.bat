@echo off

rem powershell -NoProfile -ExecutionPolicy Unrestricted 'C:\cluster-init\OpenFOAM\viz\files\download.ps1'
powershell > "powershellversion"

if %NUMBER_OF_PROCESSORS%==6 (
    goto :process
) else (
    goto :checkparaview
)

:process
if exist "NV6_DriverInstalled" (
    echo "NV6: NVIDIA Driver has already installed" >> "NV6_DriverInstalled"
    goto :checkdriver
) else (
    goto :driver
)

:driver
bitsadmin /transfer job1 "https://go.microsoft.com/fwlink/?linkid=874181" "c:\cycle\442.06_grid_win10_64bit_international_whql.exe"
c:\cycle\442.06_grid_win10_64bit_international_whql.exe -s -noreboot -clean
echo "NVIDIA driver was installed" > "C:\cycle\jetpack\logs\cluster-init\QCMD\viz\scripts\10.setup.bat.out"
echo "NV6/DriverInstalled" > "NV6_DriverInstalled"

:checkdriver
powercfg /devicequery all_devices > devicelist
for /f "delims=" %%i in (devicelist) do (
    findstr "NIVIDIA" %i%
    echo %ERRORLEVEL%
    if %ERRORLEVEL%==0 (
        goto :checkvs
)    else (
        ping 127.0.0.1 -n1 -w 60000> NUL
        goto :checkdriver
)
)

:checkvs
rem del applist
rem reg query "HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\Uninstall" /s | find "DisplayName" > applist
rem echo "checked application list"
rem for /f "delims=" %%b in (applist) do (
rem findstr "Microsoft Visual C++" %b%
rem echo %ERRORLEVEL%
rem if %ERRORLEVEL%==0 (
rem     goto :checkparaview
rem ) else (
rem     goto :installvs
rem )
rem )

rem :installvs
rem bitsadmin /transfer job3 "https://aka.ms/vs/16/release/vc_redist.x64.exe" "c:\cycle\vc_redist.x64.exe"
rem c:\cycle\vc_redist.x64.exe /install /quiet /norestart /log log.vs
rem echo "vs was installed"
rem ping 127.0.0.1 -n1 -w 60000> NUL
rem goto :checkvs

:checkparaview
rem if exsit "applist" (
rem     del "applist"
rem )
echo %DATE% > applist
rem reg query "HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\Uninstall" /s | find "DisplayName" > applist
rem reg query "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Uninstall" /s | find "DisplayName" >> applist
reg query "HKEY_LOCAL_MACHINE\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall" /s | find "DisplayName" > applist
echo "checked application list" >> "C:\cycle\jetpack\logs\\cluster-init\QCMD\viz\scripts\10.setup.bat.out"
for /f "delims=" %%a in (applist) do (
findstr "Paraview" %a%
echo %ERRORLEVEL%
if %ERRORLEVEL%==0 (
    goto :checkapp
) else (
    goto :installparaview
)
)

:installparaview
bitsadmin /transfer job2 "https://www.paraview.org/paraview-downloads/download.php?submit=Download&version=v5.7&type=binary&os=Windows&downloadFile=ParaView-5.7.0-Windows-Python3.7-msvc2015-64bit.exe" "c:\cycle\ParaView-5.7.0-Windows-Python3.7-msvc2015-64bit.exe"
c:\cycle\ParaView-5.7.0-Windows-Python3.7-msvc2015-64bit.exe /S
ping 127.0.0.1 -n1 -w 240000> NUL
echo "Paraview was installed" >> "C:\cycle\jetpack\logs\cluster-init\QCMD\viz\scripts\10.setup.bat.out"
rem goto :checkparaview
rem create paraview shortcut
cscript "C:\cluster-init\QCMD\viz\files\shortcut.vbs"
echo "running script" >> "C:\cluster-init\QCMD\viz\scripts\10.setup.bat.out"

:checkapp
rem START "C:\Program Files\ParaView-5.7.0-Windows-Python3.7-msvc2015-64bit\bin\paraview.exe"
rem echo %ERRORLEVEL%
rem if %ERRORLEVEL%==0 (
rem     goto :reboot
rem ) else (
rem    ping 127.0.0.1 -n1 -w 120000> NUL 
rem    goto :checkapp
rem )

rem NFS mount mount [NFSサーバのホスト名やIPアドレス]:/[共有名] [未使用のドライブラベル]:\\
c:\cycle\jetpack\bin\jetpack config MOUNTPOINT1 > %MOUNTPOINT1%
mount %MOUNTPOINT1% F:
echo "mountted" >> "C:\cycle\jetpack\logs\cluster-init\QCMD\viz\scripts\10.setup.bat.out"

:installvmd
c:\cycle\jetpack\bin\jetpack download vmd193win32cuda.msi --project QCMD c:\cycle\vmd193win32cuda.msi
ping 127.0.0.1 -n1 -w 5000> NUL
echo "VMD 1.9.3 downloaded."
c:\cycle\vmd193win32cuda.msi /quiet /log log.vmd
echo "create shortcut"
cscript "C:\cluster-init\QCMD\viz\files\shortcut2.vbs"
ping 127.0.0.1 -n1 -w 60000> NUL
echo "VMD was installed."

:reboot
set filename1=checkreboot
if not exist %filename1% (
    echo 1 > %filename1%
    shutdown.exe /r /t 0
)


echo "end of this script" >> "C:\cycle\jetpack\logs\cluster-init\QCMD\viz\scripts\10.setup.bat.out"
