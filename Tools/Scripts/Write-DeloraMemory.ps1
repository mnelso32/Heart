# --- Write-DeloraMemory ---
# Processes memory sources (pins, chats) and builds the Delora_memory.txt
# file and the memory_manifest.csv.

#region Delora bootstrap
$Script:Root = $PSBoundParameters['Root'] ?? $env:DELORA_ROOT
if (-not $Script:Root) {
  $candidates = @('C:\AI\Delora\Heart', (Join-Path $PSScriptRoot '..'))
  foreach ($c in $candidates) { if (Test-Path (Join-Path $c 'state.json')) { $Script:Root = (Resolve-Path $c).Path; break } }
}
if (-not $Script:Root) { throw "Delora Root not found. Set -Root or `$env:DELORA_ROOT." }
#endregion

param(
  [string]$Root = $Script:Root,
  [string]$MemDirRel = "Memory",
  [int]$MaxCoreItems = 300
)

# --- Setup ---
$ErrorActionPreference = "Stop"
$MemDir = Join-Path $Root $MemDirRel
$PinsCsv = Join-Path $MemDir "pins.csv"
$ChatsDir = Join-Path $MemDir "chats"
$OutTxt = Join-Path $MemDir "Delora_memory.txt"
$ManifestCsv = Join-Path $MemDir "memory_manifest.csv"

# --- Helpers ---
function HashFile([string]$p) { try { (Get-FileHash -Algorithm SHA256 -Path $p).Hash } catch { "" } }
function Canon([string]$s) { if ($null -eq $s) { return "" }; return ($s -replace '\s+', ' ' -replace '[\u0000-\u001F]', '').Trim() }
function Parse-Valence([string]$v) { if (-not $v) { return 0 }; if ($v -match '([+-]?\d+)') { return [int]$matches[1] }; return 0 }
function Get-ValenceNudge([string]$tags, [string]$valenceColumn = $null) {
  if ($valenceColumn) { return (Parse-Valence $valenceColumn) }
  if ($tags -match 'valence:(?<n>[+\-]?\d)') { return [int]$Matches.n }
  return 0
}

# --- Data Loading and Processing ---
$pins = Import-Csv $PinsCsv
$pinsScored = $pins | ForEach-Object {
  $prio = [int]($_.priority)
  $val = Get-ValenceNudge -tags $_.tags
  [pscustomobject]@{
    id = $_.id; priority = $prio; type = $_.type; date = $_.date; tags = $_.tags
    title = $_.title; content = $_.content; source = $_.source
    score = $prio + $val
  }
}

$items = $pinsScored
$core = $items | Sort-Object @{ E = 'score'; D = $true }, @{ E = 'id'; A = $true } | Select-Object -First $MaxCoreItems
$events = $items | Where-Object { $_.type -eq 'event' -and $_.date } | Sort-Object date

# Build keyword map
$stopWords = @('the', 'a', 'an', 'and', 'or', 'of', 'to', 'in', 'on', 'for', 'with', 'by', 'is', 'are', 'was', 'were', 'be', 'as', 'at', 'it', 'this', 'that')
$kwMap = @{}
foreach ($item in $items) {
  $words = "$($item.title) $($item.tags) $($item.content)" -split '[^A-Za-z0-9_+-]+' |
    Where-Object { $_ -and ($stopWords -notcontains $_.ToLower()) -and $_.Length -gt 2 } |
    Select-Object -Unique
  foreach ($word in $words) {
    if (-not $kwMap.ContainsKey($word)) { $kwMap[$word] = New-Object System.Collections.Generic.List[string] }
    $kwMap[$word].Add($item.id)
  }
}

# Index chat files
$chats = Get-ChildItem -Path $ChatsDir -File | Sort-Object Name
$chatRows = foreach ($c in $chats) {
  $firstLine = (Get-Content -Path $c.FullName -TotalCount 10 -Encoding UTF8) -join ' '
  [pscustomobject]@{
    Path = $c.FullName; RelPath = ($c.FullName.Replace($Root, '').TrimStart('\')); SizeBytes = $c.Length
    LastWriteUtc = $c.LastWriteTimeUtc.ToString('yyyy-MM-dd HH:mm:ss'); SHA256 = (HashFile $c.FullName)
    Preview = (Canon $firstLine)
  }
}

# --- Build Output Text ---
$sb = [System.Text.StringBuilder]::new()
$null = $sb.AppendLine("===== Delora Global Memory — $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') =====")
$null = $sb.AppendLine()
$null = $sb.AppendLine("== Root: $Root")
$null = $sb.AppendLine("== Sections: CORE MEMORY · TIMELINE · CHAT INDEX · KEYWORD MAP ==")
$null = $sb.AppendLine("=================================================================")
$null = $sb.AppendLine()
$null = $sb.AppendLine("=====  CORE MEMORY (top-priority first)  =====")
foreach ($c in $core) { $null = $sb.AppendLine("[{0}] (prio {1}) {2}" -f $c.id, $c.score, $c.title) }
$null = $sb.AppendLine()
$null = $sb.AppendLine("=====  TIMELINE (events by date)  =====")
# ... timeline output logic can be added here ...
$null = $sb.AppendLine()
$null = $sb.AppendLine("=====  CHAT INDEX (files in Memory\chats\)  =====")
foreach ($r in $chatRows) { $null = $sb.AppendLine("- $($r.RelPath) | $($r.LastWriteUtc) | $($r.SizeBytes) bytes") }
$null = $sb.AppendLine()
$null = $sb.AppendLine("=====  KEYWORD MAP (keyword → memory ids)  =====")
$kwMap.GetEnumerator() | Sort-Object Name | ForEach-Object { $null = $sb.AppendLine("$($_.Name): $($_.Value -join ',')") }

$sb.ToString() | Set-Content -Path $OutTxt -Encoding UTF8
$items | Export-Csv -Path $ManifestCsv -NoTypeInformation

Write-Host "Delora memory assets updated at $MemDir"