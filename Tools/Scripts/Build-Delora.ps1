# --- Build-Delora ---
# Orchestrates the generation of the Delora memory bundle.

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
  [switch]$SkipIndexes
)

$ErrorActionPreference = "Stop"

# --- Paths ---
$toolsDir       = Join-Path $Root 'tools'
$memDir         = Join-Path $Root 'Memory'
$indexesDir     = Join-Path $Root 'Brain\Indexes'
$bundleDir      = Join-Path $Root 'tools\bundle'

$pinsCsv        = Join-Path $memDir 'pins.csv'
$memTxt         = Join-Path $memDir 'Delora_memory.txt'
$manifestCsv    = Join-Path $memDir 'memory_manifest.csv'
$recentTxt      = Join-Path $indexesDir 'recent.txt'
$listingCsv     = Join-Path $indexesDir 'listing.csv'
$listingPrevCsv = Join-Path $indexesDir 'listing_prev.csv'
$changesTxt     = Join-Path $indexesDir 'changes.txt'

$outBundleTxt      = Join-Path $bundleDir 'Delora_bundle.txt'
$outManifestCsv    = Join-Path $bundleDir 'Delora_manifest.csv'

# --- Pre-build steps ---
# These scripts generate the core memory files we'll bundle.
& (Join-Path $toolsDir 'Write-DeloraMemory.ps1') -Root $Root
if (-not $SkipIndexes) {
  & (Join-Path $toolsDir 'Update-BrainMap.ps1') -Root $Root
}

# --- Budget and Output Management ---
[int]$script:BundleBudgetKB = 500
[int]$script:budgetBytes    = $script:BundleBudgetKB * 1024
$sb = [System.Text.StringBuilder]::new()
$manifest = New-Object System.Collections.Generic.List[object]

function Add-FileToBundle {
  param(
    [string]$SectionId,
    [string]$FilePath
  )
  $relPath = $FilePath.Replace("$Root\", "")
  $fileInfo = Get-Item $FilePath
  $fileContent = Get-Content -Path $FilePath -Raw -Encoding UTF8

  if (($sb.Length + $fileContent.Length) -lt $script:budgetBytes) {
    $null = $sb.AppendLine("== $relPath")
    $null = $sb.AppendLine($fileContent)
    $null = $sb.AppendLine()
    
    $manifest.Add([pscustomobject]@{
      SectionId    = $SectionId
      RelPath      = $relPath
      SizeBytes    = $fileInfo.Length
      LastWriteUtc = $fileInfo.LastWriteTimeUtc.ToString('yyyy-MM-dd HH:mm:ss')
      SHA256       = (Get-FileHash -Algorithm SHA256 -Path $FilePath).Hash
    })
    return $true
  }
  return $false
}

# --- Build the Bundle ---
New-Item -ItemType Directory -Path $bundleDir -Force | Out-Null

Add-FileToBundle -SectionId "MEMORY" -FilePath $memTxt
Add-FileToBundle -SectionId "MEMORY_MANIFEST" -FilePath $manifestCsv
Add-FileToBundle -SectionId "RECENT_CHANGES" -FilePath $changesTxt
Add-FileToBundle -SectionId "RECENT_FILES" -FilePath $recentTxt

# --- Finalize ---
$sb.ToString() | Set-Content -Path $outBundleTxt -Encoding UTF8
$manifest | Export-Csv -Path $outManifestCsv -NoTypeInformation

Write-Host "Delora bundle created at $outBundleTxt"