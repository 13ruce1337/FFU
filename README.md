# Using Full Flash Update (FFU) files to speed up Windows deployment

What if you could have a Windows image (Windows 10/11/Server/LTSC) that has:

- The latest Windows cumulative update
- The latest .NET cumulative update
- The latest Windows Defender Platform and Definition Updates
- The latest version of Microsoft Edge
- The latest version of OneDrive (Per-Machine)
- The latest version of Microsoft 365 Apps/Office
- The latest drivers from any of the major OEMs (Dell, HP, Lenovo, Microsoft) (yes, the latest, not some out of date enterprise CAB file from years ago)
- Winget support so you can integrate any app available from Winget directly in your image
- ARM64 support for the latest Copilot+ PCs
- The ability to bring your own drivers and apps if necessary
- Custom WinRE support

And the best part: **it takes less than two minutes** to apply the image, even with all of these updates added to the media. After setting Windows up and going through Autopilot or a provisioning package, total elapsed time ~10 minutes (depending on what Intune or your device management tool is deploying).

The Full-Flash update (FFU) process can automatically download the latest release of Windows 11, the updates mentioned above, and creates a USB drive that can be used to quickly reimage a machine.

# Getting Started

If you're new to FFU Builder or new to the FFU Builder UI version, check out the [Quick Start Guide](https://rbalsleymsft.github.io/FFU/quickstart.html). 

This will be the fastest way to create your first FFU. There's a new [FFU Builder Quickstart Youtube video](https://youtu.be/38sUc3M5Yls) based on the 2604.1 release.

## 1. Setup bootable medium (or pxe with WinPE)
If you have a flash drive with 32GB or more the fastest way to get started would be to follow the above link and use the `Create-PEMedia.ps1` script with `USBImagingToolCreator.ps1`. This will ultimately create a flash drive with 2 partitions, one bootable and one mountable storage with space for FFUs.

To create custom PE media follow these steps.
1. (Optional) Create partitioned flash disk
    * run `diskpart` in powershell
    * `list disk` REM Replace X with your USB disk number
    * `clean`
    * `convert mbr`

create partition primary size=2048
active
format fs=fat32 quick label="Boot"
assign

create partition primary
format fs=ntfs quick label="Deploy"
assign

exit


## 2. Creation of FFU
1. **Harden VHDX**
   Run the below command after copying the sysprep-ffu.xml into C:\Build\
   Note this file will be removed
   `C:\Windows\System32\Sysprep\sysprep.exe /generalize /oobe /shutdown /unattend:C:\Build\sysprep-ffu.xml`
2. **Make FFU**
   On the host or machine that has the VHDX run `make_ffu.ps1` after filling in the variables.