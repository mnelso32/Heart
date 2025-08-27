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
  [string]$Sentiment = ""
)

# --- Initialization ---
$PSScriptRoot = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition
$Root = (Resolve-Path (Join-Path $PSScriptRoot "..\..\..")).Path
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
    type = "rule"
    date = $utcDate
    tags = $Tags
    title = $Title
    content = $Content
    source = $Source
    Sentiment = $Sentiment
  }

  $allPins = @(Import-Csv -Path $pinsCsv)
  $allPins += $newPin
  $allPins | Export-Csv -Path $pinsCsv -NoTypeInformation -Encoding UTF8
  
  Write-Output "✅ Pin '$id' ('$Title') has been successfully created."

} catch {
  Write-Error "Failed to add pin. Error: $_"
}

