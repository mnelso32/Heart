# --- Save-DeloraChat ---
# Bootstraps the root path and saves a chat log to Memory\chats.

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
  [string]$Title,
  [string]$Content
)

$chatsDir = Join-Path $Root 'Memory\chats'
$safeTitle = $Title -replace '[^a-zA-Z0-9-]+', '-'
$fileName = "$(Get-Date -Format 'yyyy-MM-dd')_$safeTitle.md"
$fullPath = Join-Path $chatsDir $fileName

if (-not (Test-Path $chatsDir)) {
  New-Item -ItemType Directory -Path $chatsDir | Out-Null
}

$Content | Set-Content -Path $fullPath -Encoding UTF8
Write-Host "Chat saved to $fullPath"