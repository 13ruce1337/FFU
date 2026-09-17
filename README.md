>[!INFO] This fork was created to isolate the tools used in the original repository to more easily create custom setups.

# Getting Started

If you're new to FFU Builder or new to the FFU Builder UI version, check out the [Quick Start Guide](https://rbalsleymsft.github.io/FFU/quickstart.html). 

This will be the fastest way to create your first FFU. There's a new [FFU Builder Quickstart Youtube video](https://youtu.be/38sUc3M5Yls) based on the 2604.1 release.

# Custom Guide
## 1. Setup Bootable Medium (or PXE with WinPE)
If you have a flash drive with 32GB or more the fastest way to get started would be to follow the above link and use the `Create-PEMedia.ps1` script with `USBImagingToolCreator.ps1`. If you have 16GB or less you likely will not be able to fit an FFU file on it with WinPE, but could serve the files via SMB or another drive.

To create custom PE media follow these steps.

#### Create partitioned flash disk

   Run `diskpart` in PowerShell, then:

   ```
   list disk
   REM Replace X with your USB disk number
   select disk X
   clean
   convert mbr
   create partition primary size=2048
   active
   format fs=fat32 quick label="Boot"
   assign
   create partition primary
   format fs=ntfs quick label="Deploy"
   assign
   exit
   ```

#### Create PE Media
Use the `Create-Custom-PEMedia.ps1` script to create a `WinPE_ffu` folder. You'll copy everything from `WinPE_ffu\media` to the `BOOT` partition of the flash drive. This will make the drive bootable.

## 2. Create Virtual Machine
The [PSTools](https://github.com/13ruce1337/pstools) repository has a script (`provision_windows.ps1`) that can quickly spin up a VM after replacing the location for the Windows ISO at the top. You'll need to download the Windows ISO from the Microsoft webpage. The Windows Media Creation Tool works great. There are also instructions for using an `autounattend.xml` for further automation.

## 3. Customize Virtual Machine
Update windows and add any applications needed for the build. Once finished, this could be a good spot to export the VM or make a checkpoint.

## 4. Creation of FFU
* Harden VHDX
   Run the below command after copying the sysprep-ffu.xml into C:\Build\
   >[!WARNING] `C:\Build\sysprep-ffu.xml` will be removed
   
   `C:\Windows\System32\Sysprep\sysprep.exe /generalize /oobe /shutdown /unattend:C:\Build\sysprep-ffu.xml`
* Make FFU
   On the host or machine that has the VHDX run `make_ffu.ps1` after filling in the variables.
