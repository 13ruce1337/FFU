@echo off
setlocal
:: Check if filename argument was provided
if "%~1"=="" (
    echo [ERROR] No FFU filename provided.
    echo Usage: deploy.bat YourImageName.ffu
    exit /b 1
)

set FFU_NAME=%~1
:: Change this path if your FFU is in a different folder on your network drive
set FFU_PATH=Z:\ffu\%FFU_NAME%

echo ========================================================
echo FFU DEPLOYMENT SCRIPT
echo ========================================================
echo Image: %FFU_PATH%
echo Target: PhysicalDrive 0 (Internal SSD)
echo ========================================================

:: 1. Verify file exists
if not exist "%FFU_PATH%" (
    echo [ERROR] Could not find FFU at %FFU_PATH%
    echo Please ensure your network drive is mapped to Z:
    exit /b 1
)

:: 2. Pre-clean the disk to ensure no partition conflicts
echo [INFO] Cleaning Disk 0...
(echo select disk 0 & echo clean & echo exit) | diskpart > nul

:: 3. Apply the FFU
echo [INFO] Applying FFU... This will take 5-10 minutes.
dism /Apply-Ffu /ImageFile:"%FFU_PATH%" /ApplyDrive:\\.\PhysicalDrive0

if %errorlevel% neq 0 (
    echo.
    echo [FAIL] DISM failed with error code %errorlevel%.
    echo Check X:\windows\Logs\DISM\dism.log for details.
) else (
    echo.
    echo [SUCCESS] FFU applied and partition extended!
    echo You can now unplug the USB and reboot.
)

pause