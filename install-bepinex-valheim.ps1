# install-bepinex-valheim.ps1
# Downloads latest BepInExPack Valheim from Thunderstore,
# saves the zip in the AMP instance root,
# extracts it, then copies the pack contents into the Valheim server root.

$ErrorActionPreference = "Stop"

Write-Host "=================================================="
Write-Host "GATZ Valheim - BepInEx Latest Installer"
Write-Host "=================================================="

# Thunderstore package
$PackageAuthor = "denikson"
$PackageName = "BepInExPack_Valheim"

# AMP instance root is where this script is running from
$InstanceRoot = $PSScriptRoot

# Your template uses:
# App.BaseDirectory=./Valheim/896660/
$ServerRoot = Join-Path $InstanceRoot "Valheim\896660"

# Files/folders created in AMP instance root
$ZipPath = Join-Path $InstanceRoot "BepInExPack_Valheim-latest.zip"
$ExtractPath = Join-Path $InstanceRoot "_bepinex_extract"

Write-Host "Instance root: $InstanceRoot"
Write-Host "Server root:   $ServerRoot"

if (!(Test-Path $ServerRoot)) {
    throw "Valheim server root does not exist: $ServerRoot"
}

# Clean old extract folder
Remove-Item $ExtractPath -Recurse -Force -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Path $ExtractPath | Out-Null

# Get latest package version from Thunderstore
$ApiUrl = "https://thunderstore.io/api/experimental/package/$PackageAuthor/$PackageName/"

Write-Host "Checking latest BepInExPack Valheim version..."

$PackageInfo = Invoke-RestMethod -Uri $ApiUrl -UseBasicParsing

if (!$PackageInfo.latest.version_number) {
    throw "Could not read latest version from Thunderstore."
}

$PackageVersion = $PackageInfo.latest.version_number
$DownloadUrl = "https://thunderstore.io/package/download/$PackageAuthor/$PackageName/$PackageVersion/"

Write-Host "Latest version: $PackageVersion"
Write-Host "Downloading to: $ZipPath"

# Download latest zip to AMP instance root
Invoke-WebRequest -Uri $DownloadUrl -OutFile $ZipPath -UseBasicParsing

if (!(Test-Path $ZipPath)) {
    throw "Download failed. Zip file was not created."
}

$ZipSize = (Get-Item $ZipPath).Length

if ($ZipSize -lt 100000) {
    throw "Downloaded zip looks too small to be valid. Size: $ZipSize bytes"
}

Write-Host "Download complete. Size: $ZipSize bytes"

# Extract zip
Write-Host "Extracting zip..."

Expand-Archive -Path $ZipPath -DestinationPath $ExtractPath -Force

# Find the inner BepInExPack_Valheim folder
$InnerPack = Get-ChildItem -Path $ExtractPath -Directory -Recurse |
    Where-Object { $_.Name -eq "BepInExPack_Valheim" } |
    Select-Object -First 1

if (!$InnerPack) {
    Write-Host "Extracted files:"
    Get-ChildItem -Path $ExtractPath -Recurse | ForEach-Object {
        Write-Host $_.FullName
    }

    throw "Could not find BepInExPack_Valheim folder inside extracted package."
}

Write-Host "Found pack folder: $($InnerPack.FullName)"

# Copy pack contents into Valheim server root
Write-Host "Copying BepInEx files to server root..."

Copy-Item -Path (Join-Path $InnerPack.FullName "*") -Destination $ServerRoot -Recurse -Force

# Make sure these folders exist
$BepInExFolder = Join-Path $ServerRoot "BepInEx"
$PluginsFolder = Join-Path $BepInExFolder "plugins"
$ConfigFolder = Join-Path $BepInExFolder "config"

if (!(Test-Path $BepInExFolder)) {
    throw "BepInEx folder was not found after install."
}

if (!(Test-Path $PluginsFolder)) {
    New-Item -ItemType Directory -Path $PluginsFolder | Out-Null
}

if (!(Test-Path $ConfigFolder)) {
    New-Item -ItemType Directory -Path $ConfigFolder | Out-Null
}

Write-Host "Cleaning extract folder..."
Remove-Item $ExtractPath -Recurse -Force -ErrorAction SilentlyContinue

Write-Host "=================================================="
Write-Host "BepInExPack Valheim installed successfully."
Write-Host "Installed version: $PackageVersion"
Write-Host ""
Write-Host "Zip saved here:"
Write-Host $ZipPath
Write-Host ""
Write-Host "Server root:"
Write-Host $ServerRoot
Write-Host ""
Write-Host "Upload mods to:"
Write-Host $PluginsFolder
Write-Host ""
Write-Host "Mod configs go to:"
Write-Host $ConfigFolder
Write-Host "=================================================="