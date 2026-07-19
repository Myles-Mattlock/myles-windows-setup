# --- Set Windows Terminal as Default Terminal Application ---
Write-Host "Setting Windows Terminal as the default terminal application..." -ForegroundColor Cyan

$ConsoleRegPath = "HKCU:\Console\%%Startup"
if (-not (Test-Path $ConsoleRegPath)) {
    New-Item -Path $ConsoleRegPath -Force | Out-Null
}

# The GUID for Windows Terminal as the default terminal handler
New-ItemProperty -Path $ConsoleRegPath -Name "DelegationConsole" -Value "{2E90D11E-47C0-4660-848D-FB17B27C1743}" -PropertyType String -Force | Out-Null
New-ItemProperty -Path $ConsoleRegPath -Name "DelegationTerminal" -Value "{E12C0B9D-8BE0-45C3-B75B-16983A7E00EA}" -PropertyType String -Force | Out-Null

Write-Host "Windows Terminal set as default handler." -ForegroundColor Green

# --- Set PowerShell 7 as Default Profile in Windows Terminal ---
Write-Host "Setting PowerShell 7 as the default profile in Windows Terminal..." -ForegroundColor Cyan

$wtSettingsPaths = @(
    "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json",
    "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminalPreview_8wekyb3d8bbwe\LocalState\settings.json"
)

foreach ($path in $wtSettingsPaths) {
    if (Test-Path $path) {
        try {
            # Read and parse JSON
            $jsonContent = Get-Content $path -Raw | ConvertFrom-Json
            
            # Locate the PowerShell 7 profile (usually contains 'pwsh.exe')
            $pwshProfile = $jsonContent.profiles.list | Where-Object { $_.commandline -like "*pwsh*" -or $_.name -eq "PowerShell" } | Select-Object -First 1
            
            if ($pwshProfile -and $pwshProfile.guid) {
                # Update the default profile to match pwsh's GUID
                $jsonContent.defaultProfile = $pwshProfile.guid
                
                # Save back to file cleanly
                $jsonContent | ConvertTo-Json -Depth 10 | Set-Content $path
                Write-Host "Successfully set PowerShell 7 as default in: $path" -ForegroundColor Green
            } else {
                # Fallback if no specific GUID found: Use the standard modern pwsh GUID
                $jsonContent.defaultProfile = "{574e770e-697c-52ee-9fa0-26d831d81765}"
                $jsonContent | ConvertTo-Json -Depth 10 | Set-Content $path
                Write-Host "Applied standard PowerShell 7 GUID to defaultProfile." -ForegroundColor Green
            }
        }
        catch {
            Write-Host "Failed to update Windows Terminal settings at $path" -ForegroundColor Yellow
        }
    }
}