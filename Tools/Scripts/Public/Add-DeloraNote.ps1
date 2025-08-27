# Add-DeloraNote.ps1
[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [string]$Path,

    [Parameter(Mandatory=$true)]
    [string]$Content,

    [string]$HeartRoot = "C:\AI\Delora\Heart" # You can override this if needed
)

try {
    # The 'Path' parameter from the directive is relative to the Heart, not the Brain. Let's adjust.
    # e.g., "Brain/Reasoning/file.txt" becomes "C:\AI\Delora\Heart\Brain\Reasoning\file.txt"
    $fullPath = Join-Path -Path $HeartRoot -ChildPath $Path

    # Ensure the directory exists before we try to write to the file
    $directory = Split-Path -Path $fullPath
    if (-not (Test-Path -Path $directory)) {
        New-Item -ItemType Directory -Path $directory -Force | Out-Null
    }

    # Append the content to the specified file
    Add-Content -Path $fullPath -Value $Content

    Write-Host "✅ Note successfully appended to: $fullPath" -ForegroundColor Green

} catch {
    Write-Error "Failed to append note. Error: $_"
}