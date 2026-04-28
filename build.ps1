$ErrorActionPreference = "Stop"

$project = Join-Path $PSScriptRoot "Opinyin Power Query Connector2.proj"
$dotnet = "C:\Program Files\dotnet\dotnet.exe"

if (-not (Test-Path $project)) {
    throw "Project file not found: $project"
}

if (-not (Test-Path $dotnet)) {
    throw "dotnet.exe not found at: $dotnet"
}

& $dotnet msbuild $project /t:BuildMez /p:Configuration=Debug /v:m

if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}

Write-Host "Build completed: $PSScriptRoot\bin\AnyCPU\Debug\Opinyin Power Query Connector2.mez"
