# --- Set Windows Terminal as Default Terminal Application ---
Write-Host "Registering Windows Terminal as default terminal handler..." -ForegroundColor Cyan

$UserConsoleRegPath = "HKCU:\Console\%%Startup"

if (-not (Test-Path $UserConsoleRegPath)) {
    New-Item -Path $UserConsoleRegPath -Force | Out-Null
}

# The specific production GUIDs Windows requires to route to Windows Terminal
$ConsoleGuid  = "{2EACA947-7F5F-4CFA-BA87-8F7FBEEFBE69}"
$TerminalGuid = "{E12CFF52-A866-4C77-9A90-F570A7AA2C6B}"

try {
    # Apply settings to the Current User scope
    New-ItemProperty -Path $UserConsoleRegPath -Name "DelegationConsole" -Value $ConsoleGuid -PropertyType String -Force | Out-Null
    New-ItemProperty -Path $UserConsoleRegPath -Name "DelegationTerminal" -Value $TerminalGuid -PropertyType String -Force | Out-Null

    Write-Host "Windows Terminal successfully registered as default handler!" -ForegroundColor Green
}
catch {
    Write-Host "Failed to update user registry values: $_" -ForegroundColor Yellow
}

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