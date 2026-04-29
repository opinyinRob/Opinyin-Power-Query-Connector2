param(
    [string]$Action = "build"
)

$ErrorActionPreference = "Stop"
$project = Join-Path $PSScriptRoot "Opinyin Classifications Power Query Connector.proj"
$dotnet = "C:\Program Files\dotnet\dotnet.exe"
$ensureTools = Join-Path $PSScriptRoot "ensure-tools.ps1"

function Ensure-Tools {
    if (-not (Test-Path $ensureTools)) {
        throw "ensure-tools.ps1 not found: $ensureTools"
    }
    & $ensureTools
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to ensure Power Query SDK tools."
    }
}

switch ($Action.ToLower()) {
    "build" {
        Ensure-Tools
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
        Write-Host "Build completed: $PSScriptRoot\bin\AnyCPU\Debug\Opinyin Classifications Power Query Connector.mez"
    }
    "clean" {
        if (-not (Test-Path $project)) {
            throw "Project file not found: $project"
        }
        if (-not (Test-Path $dotnet)) {
            throw "dotnet.exe not found at: $dotnet"
        }
        & $dotnet msbuild $project /t:Clean /p:Configuration=Debug /v:m
        if ($LASTEXITCODE -ne 0) {
            exit $LASTEXITCODE
        }
        Write-Host "Clean completed."
    }
    "ensure-tools" {
        Ensure-Tools
    }
    default {
        Write-Host "Unknown action: $Action"
        Write-Host "Usage: .\\build.ps1 [build|clean|ensure-tools]"
        exit 1
    }
}
