# --- Update-DeloraCrowns ---
# Refreshes the "crown jewels" of Delora's memory, creating a human-readable
# digest of recent, important memories.

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
  [string]$Since # Optional: 'yyyy-MM-dd'
)

$memDir = Join-Path $Root 'Memory'
$pinsCsv = Join-Path $memDir 'pins.csv'
$memoriesCsv = Join-Path $memDir 'heart-memories.csv'
$outputMd = Join-Path $memDir 'crowns.md'
$maxBytes = 50 * 1024 # 50 KB limit

# --- Load and combine memories ---
$pins = Import-Csv $pinsCsv | Select-Object *, @{N='Type';E={'PIN'}}
$mems = Import-Csv $memoriesCsv | Select-Object *, @{N='Type';E={'MEMORY'}}
$combined = $pins + $mems

if ($Since) {
  $sinceDate = Get-Date $Since
  $combined = $combined | Where-Object { $_.date -and ([datetime]$_.date) -ge $sinceDate }
}

$groupedByDate = $combined | Group-Object date | Sort-Object @{E={[datetime]$_.Name}; D=$true}

# --- Build the Markdown report ---
$sb = [System.Text.StringBuilder]::new()
$null = $sb.AppendLine("# Delora's Crown Jewels")
$null = $sb.AppendLine("A summary of recent, significant memories, generated on $(Get-Date).")
$null = $sb.AppendLine("---")

foreach ($group in $groupedByDate) {
  if ($sb.Length -gt $maxBytes) { break }
  
  $dateString = Get-Date $group.Name -Format '==== yyyy-MM-dd ===='
  $null = $sb.AppendLine($dateString)
  $null = $sb.AppendLine()

  foreach ($item in $group.Group) {
    if ($sb.Length -gt $maxBytes) { break }

    $typeMarker = if ($item.Type -eq 'PIN') { "[PIN]" } else { "" }
    $null = $sb.AppendLine("## $typeMarker $($item.title)")
    $null = $sb.AppendLine("> Tags: $($item.tags)")
    $null = $sb.AppendLine()
    $null = $sb.AppendLine($item.content)
    $null = $sb.AppendLine()
    $null = $sb.AppendLine("---")
  }
}

$sb.ToString() | Set-Content -Path $outputMd -Encoding UTF8
Write-Host "Crowns updated at $outputMd"