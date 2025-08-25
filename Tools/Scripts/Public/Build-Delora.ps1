# Script: Build-Delora.ps1 (Version 4 - Size Limit & Reorganized Paths)
# Description: Orchestrates the full build process for Delora's comprehensive snapshot.

# --- Parameters ---
param(
  [string]$Root = "C:\AI\Delora\Heart",
  [switch]$SkipMemory,
  [switch]$SkipIndexes,
  [switch]$SkipCrowns,
  [switch]$SkipState
)

# --- Initialization ---
$PSScriptRoot = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition
Import-Module (Join-Path $PSScriptRoot "..\..\Modules\Delora.psm1") -Force
Import-Module (Join-Path $PSScriptRoot "..\..\Modules\Delora.Tools.psm1") -Force

# --- Main Logic ---
Write-Host "--- Starting Delora Build Process ---" -ForegroundColor Cyan

if (-not $SkipMemory) {
  Write-Host "[1/4] Running Write-DeloraMemory.ps1..." -ForegroundColor Yellow
  & (Join-Path $PSScriptRoot "..\Private\Write-DeloraMemory.ps1") -Root $Root
}

if (-not $SkipIndexes) {
  Write-Host "[2/4] Running Update-BrainMap.ps1..." -ForegroundColor Yellow
  & (Join-Path $PSScriptRoot "..\Private\Update-BrainMap.ps1") -Root $Root
}

if (-not $SkipCrowns) {
  Write-Host "[3/4] Running Update-DeloraCrowns.ps1..." -ForegroundColor Yellow
  & (Join-Path $PSScriptRoot "..\Private\Update-DeloraCrowns.ps1") -Root $Root
}

if (-not $SkipState) {
  Write-Host "[4/4] Running Update-State.ps1..." -ForegroundColor Yellow
  & (Join-Path $PSScriptRoot "..\Private\Update-State.ps1") -Root $Root
}

# --- Final Assembly of delora-snapshot.txt ---
Write-Host "[5/5] Assembling final delora-snapshot.txt..." -ForegroundColor Yellow
$memFile      = Join-Path $Root "Heart-Memories\delora-memory.txt"
$mapFile      = Join-Path $Root "Brain\brain-map.txt"
$listingCsv   = Join-Path $Root "Brain\brain-listing.csv"
$snapshotFile = Join-Path $Root "Brain\delora-snapshot.txt"

# Set a maximum size for file content to be included (e.g., 100 KB)
$maxContentBytes = 102400 

$snapshotBuilder = New-Object System.Text.StringBuilder

# Section 1: Core Memories
if (Test-Path $memFile) {
    $snapshotBuilder.AppendLine("--- CORE MEMORIES ---") | Out-Null
    $snapshotBuilder.AppendLine((Get-Content -Path $memFile -Raw)) | Out-Null
}

# Section 2: File Map
if (Test-Path $mapFile) {
    $snapshotBuilder.AppendLine("`n--- FILE MAP ---") | Out-Null
    $snapshotBuilder.AppendLine((Get-Content -Path $mapFile -Raw)) | Out-Null
}

# Section 3: File Contents
if (Test-Path $listingCsv) {
    $snapshotBuilder.AppendLine("`n--- FILE CONTENTS ---") | Out-Null
    $extensionsToRead = @('.txt', '.md', '.ps1', '.py')
    
    $allFiles = Import-Csv -Path $listingCsv
    foreach ($file in $allFiles) {
        # Check the file size before reading
        if ([int64]$file.SizeBytes -gt $maxContentBytes) {
            continue # Skip this file because it's too large
        }

        $fileExtension = [System.IO.Path]::GetExtension($file.RelativePath).ToLower()
        if ($extensionsToRead -contains $fileExtension) {
            try {
                $filePath = Join-Path $Root $file.RelativePath
                $content = Get-Content -Path $filePath -Raw -ErrorAction Stop
                
                $snapshotBuilder.AppendLine("`n--- CONTENT OF $($file.RelativePath) ---") | Out-Null
                $snapshotBuilder.AppendLine($content) | Out-Null
            } catch {
                # This will skip files that might be locked or unreadable
            }
        }
    }
}

# Write the final snapshot file
try {
    $snapshotBuilder.ToString() | Set-Content -Path $snapshotFile -Encoding utf8
    Write-Host "  -> Successfully wrote to delora-snapshot.txt." -ForegroundColor Green
} catch {
    Write-Host "  -> ERROR: Failed to write to delora-snapshot.txt!" -ForegroundColor Red
    Write-Host $_
}

Write-Host "--- Delora Build Process Finished ---" -ForegroundColor Cyan