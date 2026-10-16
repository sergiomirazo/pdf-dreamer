[CmdletBinding()]
param(
    [string]$IsccPath,
    [string]$RedistDir,
    [string]$BuildDir,
    [switch]$SkipBuild
)
$ErrorActionPreference = "Stop"
$projectRoot = Split-Path $PSScriptRoot -Parent
Push-Location $projectRoot
try {
    if (-not $IsccPath) {
        $compiler = Get-Command ISCC.exe -ErrorAction SilentlyContinue
        if ($compiler) { $IsccPath = $compiler.Source }
        else {
            $IsccPath = @(
                "${env:ProgramFiles(x86)}\Inno Setup 6\ISCC.exe",
                "$env:ProgramFiles\Inno Setup 6\ISCC.exe"
            ) | Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1
        }
    }
    if (-not $IsccPath -or -not (Test-Path -LiteralPath $IsccPath)) {
        throw "Install Inno Setup 6.3 or later; pass -IsccPath if it is not on PATH."
    }
    if (-not $RedistDir) {
        $vswhere = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"
        $visualStudio = & $vswhere -latest -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath
        if ($LASTEXITCODE -ne 0 -or -not $visualStudio) { throw "Visual Studio C++ tools not found." }
        $RedistDir = Get-ChildItem -Path "$visualStudio\VC\Redist\MSVC\*\x64\Microsoft.VC*.CRT" -Directory |
            Sort-Object FullName -Descending | Select-Object -First 1 -ExpandProperty FullName
    }
    foreach ($runtime in @("msvcp140.dll", "vcruntime140.dll", "vcruntime140_1.dll")) {
        if (-not (Test-Path -LiteralPath (Join-Path $RedistDir $runtime))) {
            throw "Missing $runtime in RedistDir. Install the Visual Studio redistributable files."
        }
    }
    if (-not $SkipBuild) {
        # Flutter 3.32 builds for the Windows host architecture; it does not
        # support --target-platform for this command.
        & flutter build windows --release
        if ($LASTEXITCODE -ne 0) { throw "Flutter Windows build failed." }
    }
    if (-not $BuildDir) {
        $BuildDir = Join-Path $projectRoot "build\windows\x64\runner\Release"
    }
    $BuildDir = (Resolve-Path -LiteralPath $BuildDir).Path
    $pubspec = Get-Content pubspec.yaml -Raw
    $appIdName = [regex]::Match($pubspec, "(?m)^name:\s*(\w+)").Groups[1].Value
    $metadata = (Get-Item -LiteralPath (Join-Path $buildDir "$appIdName.exe")).VersionInfo
    $numericVersion = "$($metadata.FileMajorPart).$($metadata.FileMinorPart).$($metadata.FileBuildPart).$($metadata.FilePrivatePart)"
    $outputDir = Join-Path $projectRoot "build\installer"
    # A generated include also lets the Inno Setup IDE compile the .iss after
    # this script has configured it, without requiring command-line /D values.
    New-Item -ItemType Directory -Force -Path $outputDir | Out-Null
    $defines = [ordered]@{
        BuildDir = $BuildDir
        RedistDir = (Resolve-Path -LiteralPath $RedistDir).Path
        OutputDir = $outputDir
        AppIdName = $appIdName
        AppName = $metadata.FileDescription
        AppPublisher = $metadata.CompanyName
        AppVersion = $metadata.FileVersion
        NumericVersion = $numericVersion
    }
    $configuration = foreach ($entry in $defines.GetEnumerator()) {
        if ([string]::IsNullOrWhiteSpace($entry.Value) -or $entry.Value -match '["\r\n]') {
            throw "Invalid installer metadata: $($entry.Key)"
        }
        '#define ' + $entry.Key + ' "' + $entry.Value + '"'
    }
    $configuration | Set-Content -LiteralPath (Join-Path $outputDir "build-config.iss") -Encoding UTF8
    & $IsccPath (Join-Path $projectRoot "installer\windows\pdf_dreamer.iss")
    if ($LASTEXITCODE -ne 0) { throw "Inno Setup compilation failed." }
    Write-Host "Installer created in $outputDir"
} finally {
    Pop-Location
}
