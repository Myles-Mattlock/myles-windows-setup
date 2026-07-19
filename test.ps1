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
            # Read the file cleanly
            $rawJson = Get-Content $path -Raw
            if ([string]::IsNullOrWhiteSpace($rawJson)) { continue }

            # Parse JSON (PS7 natively handles WT's inline comments)
            $jsonContent = ConvertFrom-Json $rawJson
            
            # Find your PowerShell 7 profile GUID
            $pwshProfile = $jsonContent.profiles.list | Where-Object { 
                $_.commandline -like "*pwsh*" -or $_.name -like "*PowerShell 7*" 
            } | Select-Object -First 1
            
            # If found, use it; otherwise use the standard native WT GUID for pwsh
            $targetGuid = if ($pwshProfile -and $pwshProfile.guid) { $pwshProfile.guid } else { "{574e770e-697c-52ee-9fa0-26d831d81765}" }
            
            # Directly assign the default profile at the root level
            $jsonContent.defaultProfile = $targetGuid
            
            # Convert back using a massive depth to guarantee NO nested arrays are flattened
            $jsonContent | ConvertTo-Json -Depth 100 | Set-Content $path -Encoding utf8
            
            Write-Host "Successfully set PowerShell 7 as default in: $path" -ForegroundColor Green
        }
        catch {
            Write-Host "Failed to update Windows Terminal settings at $path: $_" -ForegroundColor Yellow
        }
    }
}