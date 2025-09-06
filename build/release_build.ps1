# This script builds the Just-In-Time library and prepares the release files.
# Script version 1.0.0
# Created by Kili 2025-08-30

$LibMinVersion = "0.1"

# project folders
$csprojPath = (Resolve-Path "../src/CSharp/justintime/justintime.csproj")
$binBuildDir = "../src/CSharp/justintime/bin/Release/net8.0"
$libDir = "../release/modules/0.1"
$psSourceDir = "../src/PowerShell"
$ReleaseDir = "../release"
$modulesSourceDir = "$psSourceDir/modules"
$modulesReleaseDir = "$ReleaseDir/modules"
$scriptSourceDir = "$psSourceDir/scripts"
#clean up release and build directory
if (Test-Path $ReleaseDir) { Remove-Item $ReleaseDir -Recurse -Force }
if (Test-Path $binBuildDir) { Remove-Item $binBuildDir -Recurse -Force }

# 1. Update the library Version with the current date as build number
$today = Get-Date
$version = "$LibMinVersion.{0}{1:D2}{2:D2}" -f $today.Year, $today.Month, $today.Day

Write-Host "Updating $version in $csprojPath"
[xml]$csproj = Get-Content $csprojPath
$versionNode = $csproj.Project.PropertyGroup.Version
if ($versionNode) {
    $versionNode = $version
} else {
    $pg = $csproj.Project.PropertyGroup | Select-Object -First 1
    $newNode = $csproj.CreateElement("Version")
    $newNode.InnerText = $version
    $pg.AppendChild($newNode) | Out-Null
}
$FileVersion = $csproj.Project.PropertyGroup.FileVersion
if($FileVersion) {
    $FileVersion = $version
} else {
    $fg = $csproj.Project.PropertyGroup | Select-Object -First 1
    $newFileNode = $csproj.CreateElement("FileVersion")
    $newFileNode.InnerText = $version
    $fg.AppendChild($newFileNode) | Out-Null
}
$csproj.Save($csprojPath)

# 2. Build the Release version of the library
Write-Host "Building Release version..."
dotnet publish $csprojPath -c Release -r win-x64 --self-contained true 

# 3. Copy solution files
$buildOutput = "../src/CSharp/justintime/bin/Release/net8.0/win-x64/publish"
if (!(Test-Path $libDir)) { New-Item -ItemType Directory -Path $libDir | Out-Null }
Write-Host "Copying Release files to $libDir"
Copy-Item "$buildOutput/*" $libDir -Recurse -Force

# 4. PowerShell scripts
Write-Host "Copying PowerShell scripts to $scriptSourceDir"
Copy-Item "$scriptSourceDir/*.ps1" $ReleaseDir -Force

# 5. Copy Modules directory
Write-Host "Copying Modules directory to $modulesReleaseDir"
Copy-Item "$modulesSourceDir\*" $modulesReleaseDir -Recurse -Force

Write-Host "Done!"
