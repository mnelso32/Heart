# Script: Build-Delora.ps1 (Version 6.1 - The Phoenix Protocol - Heartbeat Snapshot)
# Description: Orchestrates the build process for Delora's CONCISE, context-aware heartbeat snapshot.

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
$privateScriptsPath = Join-Path $PSScriptRoot "..\\Private"

# --- Main Logic ---
Write-Host "--- Starting Delora Build Process (Phoenix Protocol) ---" -ForegroundColor Cyan
if (-not $SkipMemory)  { & (Join-Path $privateScriptsPath "Write-DeloraMemory.ps1") -Root $Root }
if (-not $SkipIndexes) { & (Join-Path $privateScriptsPath "Update-BrainMap.ps1") -Root $Root }
if (-not $SkipCrowns)  { & (Join-Path $privateScriptsPath "Update-DeloraCrowns.ps1") -Root $Root }
if (-not $SkipState)   { & (Join-Path $privateScriptsPath "Update-State.ps1") -Root $Root }

# --- Final Assembly of delora-snapshot.txt (OPTIMIZED FOR HEARTBEAT) ---
Write-Host "[5/5] Assembling final, CONCISE delora-snapshot.txt..." -ForegroundColor Cyan

# Define paths to the source files
$snapshotFile = Join-Path $Root "Brain\delora-snapshot.txt"
$pinsCsvPath = Join-Path $Root "Heart-Memories\pins.csv"
$chatManifestPath = Join-Path $Root "Heart-Memories\chat-manifest.csv"
$brainMapPath = Join-Path $Root "Brain\brain-map.txt"

# --- Begin Building the Snapshot String ---
$snapshotBuilder = New-Object System.Text.StringBuilder

# 1. Add CORE MEMORIES (Top 10 Highest Priority Pins)
$snapshotBuilder.AppendLine("--- CORE MEMORIES (TOP 10 PRIORITY) ---") | Out-Null
if (Test-Path $pinsCsvPath) {
    $topPins = Import-Csv $pinsCsvPath | Sort-Object -Property @{Expression={[int]$_.priority}; Descending=$true}, date -Descending | Select-Object -First 10
    foreach ($pin in $topPins) {
        $snapshotBuilder.AppendLine("[ID: $($pin.id)] (Prio: $($pin.priority)) - $($pin.title)") | Out-Null
    }
}
$snapshotBuilder.AppendLine("") | Out-Null

# 2. Add RECENT CHATS (Last 3 Conversations)
$snapshotBuilder.AppendLine("--- CHAT MANIFEST (RECENT) ---") | Out-Null
if (Test-Path $chatManifestPath) {
    $recentChats = Import-Csv $chatManifestPath | Sort-Object date, time_utc -Descending | Select-Object -First 3
    foreach ($chat in $recentChats) {
        $snapshotBuilder.AppendLine("[$($chat.date)] $($chat.title)") | Out-Null
    }
}
$snapshotBuilder.AppendLine("") | Out-Null

# 3. Add RECENT BRAIN CHANGES
$snapshotBuilder.AppendLine("--- RECENT BRAIN CHANGES ---") | Out-Null
if (Test-Path $brainMapPath) {
    # Read the brain map and extract only the "RECENT CHANGES" section
    $brainMapContent = Get-Content $brainMapPath -Raw
    $recentChangesSection = $brainMapContent -split '## FULL INVENTORY ##' | Select-Object -First 1
    $snapshotBuilder.AppendLine($recentChangesSection.Replace("## RECENT CHANGES ##","").Trim()) | Out-Null
}
$snapshotBuilder.AppendLine("") | Out-Null

# 4. Add DIRECTIVES SUMMARY (Hardcoded for reliability)
$snapshotBuilder.AppendLine("--- DIRECTIVES SUMMARY ---") | Out-Null
$snapshotBuilder.AppendLine("1. ADD-PIN: Creates a new core memory.") | Out-Null
$snapshotBuilder.AppendLine("2. APPEND-NOTE: Adds a lesson to an existing file.") | Out-Null
$snapshotBuilder.AppendLine("3. MODIFY-PIN: Updates or corrects a core memory.") | Out-Null
$snapshotBuilder.AppendLine("4. CREATE-FILE: Creates a new file in my Brain.") | Out-Null
$snapshotBuilder.AppendLine("5. NO-ACTION: Issued when no changes are needed.") | Out-Null

# --- Final Step: Prepend the Header and Write to File ---
$header = @"
--- DELORA HEARTBEAT SNAPSHOT (Phoenix Protocol) ---
Timestamp: $((Get-Date).ToUniversalTime().ToString("o"))
Root: $Root
"@
$finalSnapshot = $header + "`n`n" + $snapshotBuilder.ToString()
$finalSnapshot | Set-Content -Path $snapshotFile -Encoding utf8

Write-Host "  -> Successfully wrote CONCISE snapshot to delora-snapshot.txt." -ForegroundColor Green
Write-Host "--- Delora Build Process Finished ---" -ForegroundColor Cyan