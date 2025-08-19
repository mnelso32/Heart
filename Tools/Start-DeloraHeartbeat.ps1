#requires -Version 7.0
param(
  [int]$EverySec = 60,
  [switch]$EchoForChat,
  [string]$Source = 'hb'
)

Import-Module 'C:\AI\Delora\Heart\Modules\Delora.psm1' -Force -Scope Local

Write-Host "Delora heartbeat started. Tick = $EverySec s. Ctrl+C to stop." -ForegroundColor Yellow

try {
  while ($true) {
    $s = Get-DeloraState
    $s.turns++
    $utc = (Get-Date).ToUniversalTime().ToString('s')
    $s.lastRefreshUtc = $utc
    Save-DeloraState $s

    $hb = Append-DeloraHeartbeat -Utc $utc -Turns $s.turns -Source $Source
    if ($EchoForChat) { Write-Host ("HB: " + ($hb | ConvertTo-Json -Compress)) }

    Start-Sleep -Seconds $EverySec
  }
}
catch {
  Write-Warning $_
}

# main loop
$sincePublish = 0
try {
  while ($true) {
    $utc = (Get-Date).ToUniversalTime().ToString('s')

    # read/update state
    $s = Get-Content $statePath -Raw | ConvertFrom-Json
    $s.turns++
    $s.lastRefreshUtc = $utc
    $s | ConvertTo-Json | Set-Content $statePath -Encoding UTF8

    # append a compact JSON line to hb.jsonl
    [pscustomobject]@{
      utc    = $utc
      turns  = $s.turns
      source = $source
    } | ConvertTo-Json -Compress | Add-Content -Path $hbPath

    # optional publish cadence
    if ($Publish) {
      $sincePublish++
      if ($sincePublish -ge $BundleEvery) {
        $sincePublish = 0
        if ($GistId) { Publish-DeloraBundle -Root $Root -GistId $GistId }
      }
    }

    Start-Sleep -Seconds $IntervalSec
  }
}
finally {
  Write-Host "Delora heartbeat stopped at $((Get-Date).ToLongTimeString())."
}
