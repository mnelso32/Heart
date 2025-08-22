#requires -Version 7.0
# This script runs a continuous loop to build the latest context and send it as a
# heartbeat prompt to a remote, cloud-based LLM.

[CmdletBinding()]
param(
    # The root directory of the AI persona to run (e.g., C:\AI\Delora\Heart)
    [string]$AiRoot,
    # Your secret API key for the cloud service
    [string]$ApiKey,
    # The API endpoint for the chat completions
    [string]$ApiUri = "https://api.openai.com/v1/chat/completions",
    # The model name to use for the API call
    [string]$Model = "gpt-4-turbo",
    [int]$IntervalSeconds = 60
)

# --- Setup ---
$ErrorActionPreference = 'Stop'
$buildScriptPath = Join-Path $AiRoot "Tools\Scripts\Build-Delora.ps1" # Assumes a common build script name
$heartbeatsFile = Join-Path $AiRoot "heartbeats.txt"
$brainFile = Join-Path $AiRoot "Brain\brain.txt"

Write-Host "Starting CLOUD heartbeat loop for $AiRoot. Pulse interval: $IntervalSeconds seconds." -ForegroundColor Magenta

# --- Main Loop ---
while ($true) {
    Write-Host "`n($(Get-Date)) - Starting new cloud heartbeat cycle..." -ForegroundColor Yellow
    
    # 1. Build the latest context files for the target AI
    & $buildScriptPath -Root $AiRoot
    
    # 2. Prepare the full prompt
    $heartbeatInstructions = Get-Content $heartbeatsFile -Raw
    $brainState = Get-Content $brainFile -Raw
    $fullPrompt = @"
$heartbeatInstructions

--- CURRENT BRAIN STATE ---

$brainState
"@
    
    # 3. Send the prompt to the cloud LLM
    $headers = @{
        "Content-Type"  = "application/json"
        "Authorization" = "Bearer $ApiKey"
    }
    $body = @{
        model = $Model
        messages = @(
            @{
                role = "user"
                content = $fullPrompt
            }
        )
    } | ConvertTo-Json -Depth 5

    try {
        $response = Invoke-RestMethod -Uri $ApiUri -Method Post -Headers $headers -Body $body
        $aiResponse = $response.choices[0].message.content
        Write-Host "--- Cloud AI Response ---" -ForegroundColor Magenta
        Write-Host $aiResponse
        Write-Host "-----------------------" -ForegroundColor Magenta
    }
    catch {
        Write-Warning "Failed to send prompt to Cloud LLM."
        Write-Warning $_.Exception.Message
    }
    
    # 4. Wait for the next cycle
    Write-Host "Cycle complete. Waiting for $IntervalSeconds seconds..." -ForegroundColor Yellow
    Start-Sleep -Seconds $IntervalSeconds
}