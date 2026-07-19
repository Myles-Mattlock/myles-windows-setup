# --- Set Windows Terminal as Default Terminal Application ---
Write-Host "Forcing Windows Terminal as system default terminal handler..." -ForegroundColor Cyan

# Define the local machine system path for console delegation
$SysConsoleRegPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Console\Startup"

if (-not (Test-Path $SysConsoleRegPath)) {
    New-Item -Path $SysConsoleRegPath -Force | Out-Null
}

# Accurate, modern production GUIDs required by Windows to register the Windows Terminal handler package
$ConsoleGuid  = "{2EACA947-7F5F-4CFA-BA87-8F7FBEEFBE69}"
$TerminalGuid = "{E12CFF52-A866-4C77-9A90-F570A7AA2C6B}"

try {
    # Write to System Startup registry
    New-ItemProperty -Path $SysConsoleRegPath -Name "DelegationConsole" -Value $ConsoleGuid -PropertyType String -Force | Out-Null
    New-ItemProperty -Path $SysConsoleRegPath -Name "DelegationTerminal" -Value $TerminalGuid -PropertyType String -Force | Out-Null
    
    # Mirroring to HKCU for the current user session context to apply immediately without restart
    $UserConsoleRegPath = "HKCU:\Console\%%Startup"
    if (-not (Test-Path $UserConsoleRegPath)) { New-Item -Path $UserConsoleRegPath -Force | Out-Null }
    New-ItemProperty -Path $UserConsoleRegPath -Name "DelegationConsole" -Value $ConsoleGuid -PropertyType String -Force | Out-Null
    New-ItemProperty -Path $UserConsoleRegPath -Name "DelegationTerminal" -Value $TerminalGuid -PropertyType String -Force | Out-Null

    Write-Host "Windows Terminal successfully registered as the system-wide default handler!" -ForegroundColor Green
}
catch {
    Write-Host "Failed to update registry values. Ensure no group policies are blocking this action." -ForegroundColor Yellow
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