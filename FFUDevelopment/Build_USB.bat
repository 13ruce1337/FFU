@echo off
set "WORKING_DIR=C:\WinPE_amd64"
set "ADK_PATH=C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit\Windows Preinstallation Environment\amd64\WinPE_OCs"

echo [1/5] Cleaning old directory...
if exist "%WORKING_DIR%" rd /s /q "%WORKING_DIR%"

echo [2/5] Copying fresh WinPE files...
call copype amd64 "%WORKING_DIR%"

echo [3/5] Mounting boot.wim...
dism /Mount-Image /ImageFile:"%WORKING_DIR%\media\sources\boot.wim" /index:1 /MountDir:"%WORKING_DIR%\mount"

echo [4/5] Injecting required Storage and WMI packages...
:: Base WMI
dism /Image:"%WORKING_DIR%\mount" /Add-Package /PackagePath:"%ADK_PATH%\WinPE-WMI.cab"
:: Storage WMI (The fix for 0x80040154)
dism /Image:"%WORKING_DIR%\mount" /Add-Package /PackagePath:"%ADK_PATH%\WinPE-StorageWMI.cab"
dism /Image:"%WORKING_DIR%\mount" /Add-Package /PackagePath:"%ADK_PATH%\en-us\WinPE-StorageWMI_en-us.cab"
:: Enhanced Storage (FFU Provider Support)
dism /Image:"%WORKING_DIR%\mount" /Add-Package /PackagePath:"%ADK_PATH%\WinPE-EnhancedStorage.cab"
dism /Image:"%WORKING_DIR%\mount" /Add-Package /PackagePath:"%ADK_PATH%\en-us\WinPE-EnhancedStorage_en-us.cab"

echo [5/5] Unmounting and committing changes...
dism /Unmount-Image /MountDir:"%WORKING_DIR%\mount" /Commit

echo ========================================================
echo DONE! Now copy the CONTENTS of %WORKING_DIR%\media 
echo to your FAT32 USB drive.
echo ========================================================
pause