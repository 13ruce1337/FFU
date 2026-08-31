# Using Full Flash Update (FFU) files to speed up Windows deployment

### Requirements
* Hyper-V Enabled in features
```
Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V -All
```
* Poweshell 7
```
winget install --id Microsoft.PowerShell --source winget --installer-type wix
```

# Getting Started

If you're new to FFU Builder or new to the FFU Builder UI version, check out the [Quick Start Guide](https://rbalsleymsft.github.io/FFU/quickstart.html). 

This will be the fastest way to create your first FFU. There's a new [FFU Builder Quickstart Youtube video](https://youtu.be/38sUc3M5Yls) based on the 2604.1 release.

## Older Youtube Videos

[2602.1 UI Preview Quickstart Video](https://www.youtube.com/watch?v=kOIK5OmDugc) - Original quickstart video without the Fluent UI. 

[2507.1 UI Preview Video](https://www.youtube.com/watch?v=oozG1aVcg9M) - First UI Preview release video. This goes deeper than the quick start video, but is missing some features that have been added since 2507.1 was released.

[2407.2 Video](https://www.youtube.com/watch?v=rqXRbgeeKSQ) - This was the main deep-dive video on FFU Builder (before it had that name). This is a good deep dive into how the BuildFFUVM.ps1 script works, but a lot has changed since that build.
