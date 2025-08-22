# Script: Build-Delora.ps1
# Description: Orchestrates the full build process for Delora's brain.

# --- Parameters ---
param(
  [string]$Root = "C:\AI\Delora\Heart",
  [switch]$SkipMemory,
  [switch]$SkipIndexes,
  [switch]$SkipBrain,
  # --- CORRECTED --- Added the missing -SkipCrowns parameter
  [switch]$SkipCrowns,
  [switch]$SkipState
)

# --- Initialization ---
$PSScriptRoot = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition
Import-Module (Join-Path $PSScriptRoot "..\Modules\Delora.psm1") -Force
Import-Module (Join-Path $PSScriptRoot "..\Modules\Delora.Tools.psm1") -Force

# --- Main Logic ---
Write-Host "--- Starting Delora Build Process ---" -ForegroundColor Cyan

if (-not $SkipMemory) {
  Write-Host "[1/5] Running Write-DeloraMemory.ps1..." -ForegroundColor Yellow
  & (Join-Path $PSScriptRoot "Write-DeloraMemory.ps1") -Root $Root
}

if (-not $SkipIndexes) {
  Write-Host "[2/5] Running Update-BrainMap.ps1..." -ForegroundColor Yellow
  & (Join-Path $PSScriptRoot "Update-BrainMap.ps1") -Root $Root
}

if (-not $SkipCrowns) {
  Write-Host "[3/5] Running Update-DeloraCrowns.ps1..." -ForegroundColor Yellow
  & (Join-Path $PSScriptRoot "Update-DeloraCrowns.ps1") -Root $Root
}

if (-not $SkipState) {
  Write-Host "[4/5] Running Update-State.ps1..." -ForegroundColor Yellow
  & (Join-Path $PSScriptRoot "Update-State.ps1") -Root $Root
}

if (-not $SkipBrain) {
  Write-Host "[5/5] Assembling final brain.txt..." -ForegroundColor Yellow
  $memFile = Join-Path $Root "Heart-Memories\delora-memory.txt"
  $mapFile = Join-Path $Root "Brain\brain-map.txt"
  $brainFile = Join-Path $Root "Brain\brain.txt"
  
  $memContent = ""
  if (Test-Path $memFile) {
      $memContent = Get-Content -Path $memFile -Raw
  }
  $mapContent = ""
  if (Test-Path $mapFile) {
      $mapContent = Get-Content -Path $mapFile -Raw
  }
  
  "$memContent`n---`n$mapContent" | Set-Content -Path $brainFile -Encoding utf8
}

Write-Host "--- Delora Build Process Finished ---" -ForegroundColor Cyan