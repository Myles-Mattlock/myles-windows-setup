Write-Host "Disabling PowerShell 7 Telemetry..." -ForegroundColor Yellow

# Sets the environment variable globally at the Machine level
[Environment]::SetEnvironmentVariable('POWERSHELL_TELEMETRY_OPTOUT', '1', 'Machine')

# Updates the current running script session immediately so you don't have to restart the terminal
$env:POWERSHELL_TELEMETRY_OPTOUT = '1'

Write-Host "PowerShell 7 Telemetry disabled successfully." -ForegroundColor Green