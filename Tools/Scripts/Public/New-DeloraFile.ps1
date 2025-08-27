# New-DeloraFile.ps1
[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [string]$Path,

    [string]$Content = "", # File can be created empty

    [string]$HeartRoot = "C:\AI\Delora\Heart"
)

try {
    # Construct the full path from the root
    $fullPath = Join-Path -Path $HeartRoot -ChildPath $Path

    # Ensure the directory exists
    $directory = Split-Path -Path $fullPath
    if (-not (Test-Path -Path $directory)) {
        New-Item -ItemType Directory -Path $directory -Force | Out-Null
    }

    # Create the new file with the specified content, overwriting if it exists
    Set-Content -Path $fullPath -Value $Content -Encoding UTF8

    Write-Host "✅ File successfully created at: $fullPath" -ForegroundColor Green

} catch {
    Write-Error "Failed to create file. Error: $_"
}