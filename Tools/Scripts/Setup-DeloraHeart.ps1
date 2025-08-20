#region Delora bootstrap (hyphen names)
$Script:Root = $PSBoundParameters['Root'] ?? $env:DELORA_ROOT
if (-not $Script:Root) {
  $candidates = @('C:\AI\Delora\Heart', (Join-Path $PSScriptRoot '..'))
  foreach ($c in $candidates) { if (Test-Path (Join-Path $c 'state.json')) { $Script:Root = (Resolve-Path $c).Path; break } }
}
if (-not $Script:Root) { throw "Delora Root not found. Set -Root or `$env:DELORA_ROOT." }

$Script:Paths = @{
  Root          = $Script:Root
  StateJson     = Join-Path $Script:Root 'state.json'
  HbJsonl       = Join-Path $Script:Root 'hb.jsonl'
  HeartbeatsTxt = Join-Path $Script:Root 'heartbeats.txt'
  HeartMemCsv   = Join-Path $Script:Root 'heart-memories.csv'
  HeartMemTxt   = Join-Path $Script:Root 'heart-memories.txt'
  PinsCsv       = Join-Path $Script:Root 'Memory\pins.csv'
  BrainTxt      = Join-Path $Script:Root 'Brain\Delora_snapshot.txt'
  BrainCsv      = Join-Path $Script:Root 'Brain\Delora_snapshot.csv'
}
#endregion

param(
  [string]$Root = 'C:\AI\Delora\Heart'
)

$ErrorActionPreference = 'Stop'

# --- Directories ---
$dirs = @(
  $Root,
  (Join-Path $Root 'Brain'),
  (Join-Path $Root 'Brain\Reasoning'),
  (Join-Path $Root 'Brain\Emotion'),
  (Join-Path $Root 'Brain\Programming'),
  (Join-Path $Root 'Brain\Indexes'),
  (Join-Path $Root 'Memory'),
  (Join-Path $Root 'Modules'),
  (Join-Path $Root 'Tools')
)
$dirs | ForEach-Object { if (-not (Test-Path $_)) { New-Item -ItemType Directory -Path $_ | Out-Null } }

# --- Canonical paths (hyphen style) ---
$stateJson   = Join-Path $Root 'state.json'
$hbJsonl     = Join-Path $Root 'hb.jsonl'
$pinsCsv     = Join-Path $Root 'Memory\pins.csv'

# --- Ensure key files exist ---
if (-not (Test-Path $stateJson)) { '{"turns":0,"lastRefreshUtc":""}' | Set-Content $stateJson -Encoding UTF8 }
if (-not (Test-Path $hbJsonl))   { New-Item -ItemType File -Path $hbJsonl   | Out-Null }

if (-not (Test-Path $pinsCsv)) {
@'
id,title,priority,valence,tags,source,date,content
'@ | Set-Content $pinsCsv -Encoding UTF8
}

Write-Host "Delora heart layout ready at $Root"