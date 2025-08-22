# Script: Add-DeloraPin.ps1
# Description: Adds a new memory pin to the pins.csv file.

# --- Parameters ---
param(
  [Parameter(Mandatory=$true)][string]$Title,
  [Parameter(Mandatory=$true)][string]$Content,
  [string]$Tags = "",
  [string]$Type = "note",
  [int]$Priority = 3,
  [string]$Source = "local",
  [switch]$SkipIndexes,
  # --- NEW --- Added an optional parameter for sentiment.
  [string]$Sentiment = "" 
)

# --- Initialization ---
$PSScriptRoot = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition
$Root = Split-Path -Path $PSScriptRoot -Parent | Split-Path -Parent
$pinsCsv = Join-Path $Root "Heart-Memories\pins.csv"
$buildScript = Join-Path $PSScriptRoot "Build-Delora.ps1"

# --- Main Logic ---
try {
  $utcDate = (Get-Date).ToUniversalTime().ToString("yyyy-MM-dd")
  $timestamp = (Get-Date).ToUniversalTime().ToString("yyyyMMddHHmmss")
  $id = "D-PIN-$timestamp"

  $newPin = [pscustomobject]@{
    id = $id
    priority = $Priority
    type = $Type
    date = $utcDate
    tags = $Tags
    title = $Title
    content = $Content
    source = $Source
    # --- NEW --- Added the new Sentiment property to the object.
    Sentiment = $Sentiment
  }

  $newPin | Export-Csv -Path $pinsCsv -Append -NoTypeInformation -Encoding UTF8
  Write-Host "✔ Successfully added new pin '$id'" -ForegroundColor Green
  
  # --- Housekeeping ---
  if (-not $SkipIndexes) {
    & $buildScript -SkipMemory -SkipCrowns -SkipState
  }

} catch {
  Write-Host "ERROR: Failed to add new pin." -ForegroundColor Red
  Write-Host $_
}