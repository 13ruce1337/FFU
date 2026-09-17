<#
.SYNOPSIS
    Builds a WinPE image for FFU capture/deployment with required optional
    components injected, then commits the image for use with wimboot/iPXE.

.NOTES
    Can be run from a normal PowerShell prompt (elevated). The script
    internally calls DandISetEnv.bat (from the Windows ADK) before invoking
    copype, so you no longer need to launch the "Deployment and Imaging
    Tools Environment" shortcut manually.

    Driver injection is model-agnostic: point $DriverRoot at a folder tree
    containing driver packages for every model you support (organize into
    subfolders however you like, e.g. C:\Drivers\Dell\OptiPlex7090,
    C:\Drivers\HP\EliteDesk800G6, C:\Drivers\Lenovo\M90q, etc.). DISM will
    recurse the whole tree and stage every matching package into the
    image's driver store; WinPE's Plug and Play will select and load only
    the driver(s) that match the hardware actually present at boot time.
#>

param(
    [string]$Arch        = "amd64",
    [string]$WorkingDir  = "$PSScriptRoot\WinPE_ffu",
    [string]$DriverRoot  = "$PSScriptRoot\Drivers",
    [string]$AdkRoot     = "C:\Program Files (x86)\Windows Kits\10\",
    [string]$AdkOcRoot   = "C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit\Windows Preinstallation Environment"
)

$ErrorActionPreference = "Stop"

# ---------------------------------------------------------------------------
# 1. Create the working copy of WinPE media (always rebuilt from scratch)
#    copype is a batch script that lives under the ADK's Deployment Tools
#    folder and depends on environment variables/PATH entries set up by
#    DandISetEnv.bat. Rather than requiring you to launch the special
#    "Deployment and Imaging Tools Environment" shell, we run DandISetEnv.bat
#    and copype together in a single cmd.exe session so this script works
#    from a plain PowerShell prompt.
# ---------------------------------------------------------------------------
if (Test-Path $WorkingDir) {
    Write-Host "Existing working directory found at $WorkingDir, removing so it can be rebuilt..."
    Remove-Item -Path $WorkingDir -Recurse -Force
}

$DandIEnv = Join-Path $AdkRoot "Assessment and Deployment Kit\Deployment Tools\DandISetEnv.bat"
if (-not (Test-Path $DandIEnv)) {
    throw "Could not find DandISetEnv.bat at '$DandIEnv'. Check `$AdkRoot points at your ADK install (e.g. 'C:\Program Files (x86)\Windows Kits\10\')."
}

Write-Host "Creating WinPE working copy at $WorkingDir ..."
& cmd /c """$DandIEnv"" && copype $Arch ""$WorkingDir"""
if ($LASTEXITCODE -ne 0) {
    throw "copype failed with exit code $LASTEXITCODE."
}

$BootWim  = Join-Path $WorkingDir "media\sources\boot.wim"
$MountDir = Join-Path $WorkingDir "mount"

if (-not (Test-Path $MountDir)) {
    New-Item -ItemType Directory -Path $MountDir | Out-Null
}

# ---------------------------------------------------------------------------
# 2. Mount the boot.wim (index 1)
# ---------------------------------------------------------------------------
Write-Host "Mounting $BootWim ..."
Dism /Mount-Image /ImageFile:$BootWim /Index:1 /MountDir:$MountDir

# ---------------------------------------------------------------------------
# 3. Inject optional components in dependency order
#    Order matters: WMI -> NetFX -> Scripting -> PowerShell -> StorageWMI
# ---------------------------------------------------------------------------
$OcPackageDir = Join-Path $AdkOcRoot "$Arch\WinPE_OCs"

$Packages = @(
    "WinPE-WMI.cab",
    "WinPE-NetFX.cab",
    "WinPE-Scripting.cab",
    "WinPE-PowerShell.cab",
    "WinPE-StorageWMI.cab"
)

foreach ($pkg in $Packages) {
    $pkgPath = Join-Path $OcPackageDir $pkg
    if (-not (Test-Path $pkgPath)) {
        Write-Warning "Package not found, skipping: $pkgPath"
        continue
    }
    Write-Host "Adding package: $pkg"
    Dism /Image:$MountDir /Add-Package /PackagePath:$pkgPath
}

# ---------------------------------------------------------------------------
# 4. (Optional but recommended) Add matching language packs for
#    NetFX/PowerShell so error messages resolve correctly.
#    Uncomment and adjust locale if needed.
# ---------------------------------------------------------------------------
# $LangPackDir = Join-Path $OcPackageDir "en-us"
# Dism /Image:$MountDir /Add-Package /PackagePath:(Join-Path $LangPackDir "WinPE-WMI_en-us.cab")
# Dism /Image:$MountDir /Add-Package /PackagePath:(Join-Path $LangPackDir "WinPE-NetFX_en-us.cab")
# Dism /Image:$MountDir /Add-Package /PackagePath:(Join-Path $LangPackDir "WinPE-Scripting_en-us.cab")
# Dism /Image:$MountDir /Add-Package /PackagePath:(Join-Path $LangPackDir "WinPE-PowerShell_en-us.cab")
# Dism /Image:$MountDir /Add-Package /PackagePath:(Join-Path $LangPackDir "WinPE-StorageWMI_en-us.cab")

# ---------------------------------------------------------------------------
# 5. Inject NIC / storage / chipset drivers for ALL supported models.
#    $DriverRoot should contain driver packages for every model that will
#    PXE-boot this image. DISM recurses the whole tree and stages every
#    matching package; PnP at boot time loads only what matches the
#    hardware actually present. No per-model targeting is required here.
# ---------------------------------------------------------------------------
if (Test-Path $DriverRoot) {
    $infCount = (Get-ChildItem -Path $DriverRoot -Filter *.inf -Recurse -ErrorAction SilentlyContinue).Count
    Write-Host "Found $infCount driver INF(s) under $DriverRoot"

    if ($infCount -eq 0) {
        Write-Warning "No .inf files found under $DriverRoot -- check that driver packages have been extracted (not left as .exe installers) before injecting."
    } else {
        Write-Host "Adding drivers from $DriverRoot (recursive, multi-model)..."
        # /ForceUnsigned can be appended if any OEM packages lack WHQL signing:
        # Dism /Image:$MountDir /Add-Driver /Driver:$DriverRoot /Recurse /ForceUnsigned
        Dism /Image:$MountDir /Add-Driver /Driver:$DriverRoot /Recurse
    }
} else {
    Write-Warning "Driver root $DriverRoot not found, skipping driver injection."
}

# ---------------------------------------------------------------------------
# 6. Commit and unmount
# ---------------------------------------------------------------------------
Write-Host "Committing changes and unmounting image..."
Dism /Unmount-Image /MountDir:$MountDir /Commit

# ---------------------------------------------------------------------------
# 7. Report final location
# ---------------------------------------------------------------------------
Write-Host ""
Write-Host "Build complete."
Write-Host "boot.wim located at: $BootWim"
Write-Host "Copy the following files to your DRBL TFTP root under /tftpboot/winpe/:"
Write-Host "  - $BootWim"
Write-Host "  - $(Join-Path $WorkingDir 'media\bootmgr')          (rename to bootmgr.exe)"
Write-Host "  - $(Join-Path $WorkingDir 'media\boot\BCD')"
Write-Host "  - $(Join-Path $WorkingDir 'media\boot\boot.sdi')"
