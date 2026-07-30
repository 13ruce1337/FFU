# Configuration
$LogFolder = "C:\Windows\Temp"
$DestinationFolder = "C:\FFUDevelopment"
$ZipFile = Join-Path $LogFolder "FFU-1337.zip"
$ExtractPath = Join-Path $LogFolder "FFU-1337"

# GitHub source
$RepoZipUrl = "https://github.com/13ruce1337/FFU/archive/refs/heads/1337.zip"

# Start transcript
$TranscriptFile = Join-Path $LogFolder ("FFUDeploy_{0}.log" -f (Get-Date -Format "yyyyMMdd_HHmmss"))
Start-Transcript -Path $TranscriptFile -Append

try {
    Write-Host "Beginning FFUDevelopment deployment..."

    # Remove existing destination if it exists
    if (Test-Path $DestinationFolder) {
        Write-Host "Removing existing directory: $DestinationFolder"
        Remove-Item -Path $DestinationFolder -Recurse -Force
    }

    # Remove old ZIP if present
    if (Test-Path $ZipFile) {
        Write-Host "Removing previous ZIP: $ZipFile"
        Remove-Item $ZipFile -Force
    }

    # Download latest code from GitHub
    Write-Host "Downloading latest FFU branch (1337)..."
    Invoke-WebRequest `
        -Uri $RepoZipUrl `
        -OutFile $ZipFile `
        -UseBasicParsing

    if (-not (Test-Path $ZipFile)) {
        throw "Failed to download repository ZIP."
    }

    # Remove old extraction folder if present
    if (Test-Path $ExtractPath) {
        Write-Host "Removing previous extraction folder: $ExtractPath"
        Remove-Item -Path $ExtractPath -Recurse -Force
    }

    # Extract archive
    Write-Host "Extracting archive..."
    Expand-Archive -Path $ZipFile -DestinationPath $ExtractPath -Force

    # Locate FFUDevelopment folder inside extracted content
    $SourceFolder = Join-Path $ExtractPath "FFU-1337\FFUDevelopment"

    if (-not (Test-Path $SourceFolder)) {
        throw "Source folder not found: $SourceFolder"
    }

    # Copy to destination
    Write-Host "Copying FFUDevelopment to $DestinationFolder"
    Copy-Item -Path $SourceFolder -Destination $DestinationFolder -Recurse -Force

    # Cleanup
    Write-Host "Cleaning up temporary files"
    Remove-Item -Path $ExtractPath -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item -Path $ZipFile -Force -ErrorAction SilentlyContinue

    Write-Host "Deployment completed successfully."
}
catch {
    Write-Error $_.Exception.Message
    throw
}
finally {
    Stop-Transcript
}
