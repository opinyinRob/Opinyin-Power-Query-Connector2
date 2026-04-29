$ErrorActionPreference = "Stop"

$toolsPath = Join-Path $PSScriptRoot ".pqtools/Microsoft.PowerQuery.SdkTools.2.152.3/tools"
$pqTest = Join-Path $toolsPath "PQTest.exe"
if (Test-Path $pqTest) {
    Write-Host "Power Query SDK tools already present."
    exit 0
}

$root = Join-Path $PSScriptRoot ".pqtools"
$version = "2.152.3"
$pkgName = "Microsoft.PowerQuery.SdkTools.$version"
$pkgDir = Join-Path $root $pkgName
$nupkg = Join-Path $root "$pkgName.nupkg"
$zip = Join-Path $root "$pkgName.zip"

New-Item -ItemType Directory -Path $root -Force | Out-Null
Invoke-WebRequest -Uri "https://api.nuget.org/v3-flatcontainer/microsoft.powerquery.sdktools/$version/microsoft.powerquery.sdktools.$version.nupkg" -OutFile $nupkg
Copy-Item $nupkg $zip -Force
if (Test-Path $pkgDir) { Remove-Item $pkgDir -Recurse -Force }
Expand-Archive -Path $zip -DestinationPath $pkgDir -Force
if (-not (Test-Path $pqTest)) { throw 'Power Query SDK tools installation failed.' }
Write-Host "Installed Power Query SDK tools at $toolsPath"
