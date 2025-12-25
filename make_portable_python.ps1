<#
.SYNOPSIS
    Creates a portable Python environment with all dependencies bundled.
    No Python installation required - this script is completely standalone.

.DESCRIPTION
    Downloads Python embeddable package, sets up pip, and installs requirements.
    The output is a standalone python folder that runs on any Windows machine.

.PARAMETER Requirements
    Path to requirements.txt file (required)

.PARAMETER PythonVersion
    Python version to use: 3.9, 3.10, 3.11, 3.12 (default: 3.11)

.PARAMETER OutputDir
    Output directory (default: .\portable_python)

.EXAMPLE
    .\make_portable_python.ps1 -Requirements requirements.txt -PythonVersion 3.11 -OutputDir .\portable_python
#>

param(
    [string]$Requirements,
    [string]$PythonVersion = "3.11",
    [string]$OutputDir = ".\portable_python"
)

# Python embeddable package URLs
$PythonUrls = @{
    "3.12" = "https://www.python.org/ftp/python/3.12.7/python-3.12.7-embed-amd64.zip"
    "3.11" = "https://www.python.org/ftp/python/3.11.9/python-3.11.9-embed-amd64.zip"
    "3.10" = "https://www.python.org/ftp/python/3.10.11/python-3.10.11-embed-amd64.zip"
    "3.9"  = "https://www.python.org/ftp/python/3.9.13/python-3.9.13-embed-amd64.zip"
}

$GetPipUrl = "https://bootstrap.pypa.io/get-pip.py"

# Validate parameters
if (-not $Requirements) {
    Write-Host ""
    Write-Host "Portable Python Maker" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Usage:" -ForegroundColor Yellow
    Write-Host "  .\make_portable_python.ps1 -Requirements <path> [-PythonVersion <ver>] [-OutputDir <path>]"
    Write-Host ""
    Write-Host "Flags:" -ForegroundColor Yellow
    Write-Host "  -Requirements   Path to requirements.txt file (required)"
    Write-Host "  -PythonVersion  Python version: 3.9, 3.10, 3.11, 3.12 (default: 3.11)"
    Write-Host "  -OutputDir      Output directory (default: .\portable_python)"
    Write-Host ""
    Write-Host "Example:" -ForegroundColor Yellow
    Write-Host "  .\make_portable_python.ps1 -Requirements requirements.txt -PythonVersion 3.11 -OutputDir .\portable_python"
    Write-Host ""
    exit 1
}

if (-not $PythonUrls.ContainsKey($PythonVersion)) {
    Write-Host "Error: Unsupported Python version: $PythonVersion" -ForegroundColor Red
    Write-Host "Supported versions: $($PythonUrls.Keys -join ', ')"
    exit 1
}

if ($Requirements -and -not (Test-Path $Requirements)) {
    Write-Host "Error: Requirements file not found: $Requirements" -ForegroundColor Red
    exit 1
}

# Setup
$OutputDir = [System.IO.Path]::GetFullPath($OutputDir)
$PythonExe = Join-Path $OutputDir "python.exe"

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "          Portable Python Maker (Standalone)                " -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

# Clean output directory if exists
if (Test-Path $OutputDir) {
    Write-Host "Cleaning existing output directory..." -ForegroundColor Yellow
    Remove-Item -Path $OutputDir -Recurse -Force
}

New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null

# Step 1: Download Python embeddable
Write-Host ""
Write-Host "[1/4] Downloading Python $PythonVersion embeddable..." -ForegroundColor Green

$PythonUrl = $PythonUrls[$PythonVersion]
$PythonZip = Join-Path $env:TEMP "python-embed.zip"

try {
    $ProgressPreference = 'SilentlyContinue'  # Faster download
    Invoke-WebRequest -Uri $PythonUrl -OutFile $PythonZip -UseBasicParsing
    Write-Host "  Downloaded Python embeddable package" -ForegroundColor Gray
} catch {
    Write-Host "Error downloading Python: $_" -ForegroundColor Red
    exit 1
}

# Extract Python
Write-Host "  Extracting..." -ForegroundColor Gray
Expand-Archive -Path $PythonZip -DestinationPath $OutputDir -Force
Remove-Item $PythonZip -Force

# Enable pip by modifying python*._pth file
$pthFile = Get-ChildItem -Path $OutputDir -Filter "python*._pth" | Select-Object -First 1
if ($pthFile) {
    $content = Get-Content $pthFile.FullName -Raw
    $content = $content -replace "#import site", "import site"
    if ($content -notmatch "Lib\\site-packages") {
        $content += "`nLib\site-packages`n"
    }
    Set-Content -Path $pthFile.FullName -Value $content -NoNewline
    Write-Host "  Configured Python for pip support" -ForegroundColor Gray
}

# Create Lib/site-packages directory
$sitePackages = Join-Path $OutputDir "Lib\site-packages"
New-Item -ItemType Directory -Path $sitePackages -Force | Out-Null

# Create sitecustomize.py to add current working directory to path
$siteCustomize = Join-Path $sitePackages "sitecustomize.py"
$siteCustomizeContent = @"
import sys
import os
cwd = os.getcwd()
if cwd not in sys.path:
    sys.path.insert(0, cwd)
"@
Set-Content -Path $siteCustomize -Value $siteCustomizeContent
Write-Host "  Added sitecustomize.py for working directory support" -ForegroundColor Gray

# Step 2: Install pip
Write-Host ""
Write-Host "[2/4] Installing pip..." -ForegroundColor Green

$getPipPath = Join-Path $env:TEMP "get-pip.py"
try {
    Invoke-WebRequest -Uri $GetPipUrl -OutFile $getPipPath -UseBasicParsing
    Write-Host "  Downloaded get-pip.py" -ForegroundColor Gray
} catch {
    Write-Host "Error downloading get-pip.py: $_" -ForegroundColor Red
    exit 1
}

# Run get-pip.py
$pipResult = & $PythonExe $getPipPath --no-warn-script-location 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "Error installing pip: $pipResult" -ForegroundColor Red
    exit 1
}
Remove-Item $getPipPath -Force
Write-Host "  pip installed successfully" -ForegroundColor Gray

# Step 3: Install packages
Write-Host ""
Write-Host "[3/4] Installing packages..." -ForegroundColor Green

$reqPath = [System.IO.Path]::GetFullPath($Requirements)
Write-Host "  Installing from: $reqPath" -ForegroundColor Gray
& $PythonExe -m pip install -r $reqPath --no-warn-script-location
if ($LASTEXITCODE -ne 0) {
    Write-Host "Error installing requirements" -ForegroundColor Red
    exit 1
}

Write-Host "  All packages installed successfully" -ForegroundColor Gray

# Step 4: Done
Write-Host ""
Write-Host "[4/4] Finalizing..." -ForegroundColor Green

# Get folder size
$size = (Get-ChildItem -Path $OutputDir -Recurse | Measure-Object -Property Length -Sum).Sum / 1MB
$sizeStr = "{0:N0} MB" -f $size

# Done!
Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "          Portable Python Created Successfully!             " -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Output: $OutputDir" -ForegroundColor White
Write-Host "Size:   $sizeStr" -ForegroundColor White
Write-Host ""
Write-Host "Usage:" -ForegroundColor Yellow
Write-Host "  .\portable_python\python.exe                   - Launch Python interpreter"
Write-Host "  .\portable_python\python.exe script.py         - Run a Python script"
Write-Host "  .\portable_python\python.exe -m pip install X  - Install more packages"
Write-Host "  .\portable_python\python.exe -m pip list       - List installed packages"
Write-Host ""
Write-Host "Copy the folder to any Windows PC - no Python installation needed!" -ForegroundColor Green
