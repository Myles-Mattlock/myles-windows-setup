# ==============================================================================
# --- DEFAULT TERMINAL APPLICATION SETUP ---
# ==============================================================================
Write-Host "Configuring Windows Terminal as default terminal handler..." -ForegroundColor Cyan

# 1. Clear out user/system overrides so Windows forces the custom delegation mapping
$RegClearPaths = @("HKCU:\Console", "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Console")
foreach ($rPath in $RegClearPaths) {
    if (Test-Path "$rPath\Startup") { Remove-Item -Path "$rPath\Startup" -Recurse -Force -ErrorAction SilentlyContinue }
}

# 2. Re-establish the precise user-level handler configuration
$UserConsoleRegPath = "HKCU:\Console\%%Startup"
if (-not (Test-Path $UserConsoleRegPath)) { New-Item -Path $UserConsoleRegPath -Force | Out-Null }

$ConsoleGuid  = "{2EACA947-7F5F-4CFA-BA87-8F7FBEEFBE69}"
$TerminalGuid = "{E12CFF52-A866-4C77-9A90-F570A7AA2C6B}"

try {
    New-ItemProperty -Path $UserConsoleRegPath -Name "DelegationConsole" -Value $ConsoleGuid -PropertyType String -Force | Out-Null
    New-ItemProperty -Path $UserConsoleRegPath -Name "DelegationTerminal" -Value $TerminalGuid -PropertyType String -Force | Out-Null
    Write-Host "Successfully registered Windows Terminal handler in Registry." -ForegroundColor Green
}
catch {
    Write-Host "Registry update warning: $_" -ForegroundColor Yellow
}


# ==============================================================================
# --- WINDOWS TERMINAL DEFAULT PROFILE SETUP ---
# ==============================================================================
Write-Host "Configuring PowerShell 7 as the default Windows Terminal profile..." -ForegroundColor Cyan

# Explicitly defining the settings file locations so they are available to the loop
$wtSettingsPaths = @(
    "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json",
    "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminalPreview_8wekyb3d8bbwe\LocalState\settings.json"
)

foreach ($path in $wtSettingsPaths) {
    if (Test-Path $path) {
        try {
            $rawJson = Get-Content $path -Raw
            if ([string]::IsNullOrWhiteSpace($rawJson)) { continue }

            $jsonContent = ConvertFrom-Json $rawJson
            
            # Find the profile matching pwsh execution or naming convention
            $pwshProfile = $jsonContent.profiles.list | Where-Object { 
                $_.commandline -like "*pwsh*" -or $_.name -like "*PowerShell 7*" -or $_.name -eq "PowerShell"
            } | Select-Object -First 1
            
            $targetGuid = if ($pwshProfile -and $pwshProfile.guid) { $pwshProfile.guid } else { "{574e770e-697c-52ee-9fa0-26d831d81765}" }
            
            $jsonContent.defaultProfile = $targetGuid
            
            # Save structure with max depth and clean UTF8 structure
            $jsonContent | ConvertTo-Json -Depth 100 | Set-Content $path -Encoding utf8
            
            Write-Host "Successfully set PowerShell 7 as default in: $path" -ForegroundColor Green
        }
        catch {
            Write-Host "Failed to update Windows Terminal settings at ${path}: $_" -ForegroundColor Yellow
        }
    }
}