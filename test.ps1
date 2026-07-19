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
            # Read raw text
            $rawJson = Get-Content $path -Raw
            $jsonObj = ConvertFrom-Json $rawJson
            
            # Find the actual dynamic GUID from the profiles list
            $pwshProfile = $jsonObj.profiles.list | Where-Object { $_.commandline -like "*pwsh*" -or $_.name -eq "PowerShell" } | Select-Object -First 1
            
            $targetGuid = if ($pwshProfile -and $pwshProfile.guid) { $pwshProfile.guid } else { "{574e770e-697c-52ee-9fa0-26d831d81765}" }
            
            # Use regex string replacement to swap out the defaultProfile line cleanly, preserving exact file structure
            if ($rawJson -match '"defaultProfile"\s*:\s*"[^"]+"') {
                $updatedJson = $rawJson -replace '"defaultProfile"\s*:\s*"[^"]+"', "`"defaultProfile`": `"$targetGuid`""
            } else {
                # If defaultProfile key isn't found at the root level, insert it right after the opening brace
                $updatedJson = $rawJson -replace '^(\s*\{)', "`$1`n    `"defaultProfile`": `"$targetGuid`","
            }
            
            Set-Content -Path $path -Value $updatedJson -NoNewline
            Write-Host "Successfully patched Windows Terminal defaultProfile in: $path" -ForegroundColor Green
        }
        catch {
            Write-Host "Failed to update Windows Terminal settings at $path: $_" -ForegroundColor Yellow
        }
    }
}