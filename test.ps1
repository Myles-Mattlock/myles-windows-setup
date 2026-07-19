$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

Write-Host "--- PHASE 0: Configuring Update Policies ---" -ForegroundColor Cyan

# Check if the sub-script exists before running
$originalPolicy = Get-ExecutionPolicy

# 2. Set it to RemoteSigned
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope LocalMachine -Force

if (Test-Path ".\WindowsInstaller\AddWifi.ps1") {
    Write-Host "--- Adding Wifi connection -Home wifi ---" -ForegroundColor Cyan
    .\WindowsInstaller\AddWifi.ps1
    Start-Sleep -Seconds 15
}

# turn off delivery omtimzation
New-PSDrive -Name HKU -PSProvider Registry -Root HKEY_USERS
New-ItemProperty -Path "HKU:\S-1-5-20\Software\Microsoft\Windows\CurrentVersion\DeliveryOptimization\Settings" -Name "DownloadMode" -Value 0 -PropertyType DWord -Force

# Registry Update Policies
$WU = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate"
if (-not (Test-Path $WU)) { New-Item -Path $WU -Force | Out-Null }
Set-ItemProperty -Path $WU -Name "DeferFeatureUpdates" -Value 1
Set-ItemProperty -Path $WU -Name "DeferFeatureUpdatesPeriodInDays" -Value 365
Set-ItemProperty -Path $WU -Name "DeferQualityUpdates" -Value 1
Set-ItemProperty -Path $WU -Name "DeferQualityUpdatesPeriodInDays" -Value 4
Set-ItemProperty -Path $WU -Name "EnableOptionalUpdates" -Value 0
gpupdate /force

# Install packages
winget install microsoft.powershell google.chrome --accept-source-agreements --accept-package-agreements

# Run Updates
winget update --all --accept-source-agreements --accept-package-agreements
# --------------------------

Write-Host "System Tweaks & Debloat ---" -ForegroundColor Cyan

# Helper function to check and apply registry modifications efficiently
function Set-RegistryTweak ($Path, $Name, $Value, $Type = "DWord") {
    $currentValue = Get-ItemPropertyValue -Path $Path -Name $Name -ErrorAction SilentlyContinue
    if ($currentValue -ne $Value) {
        if (-not (Test-Path $Path)) { New-Item -Path $Path -Force | Out-Null }
        Set-ItemProperty -Path $Path -Name $Name -Value $Value -Type $Type
    }
}

# Explorer & Taskbar Updates (Optimized via Helper)
Set-RegistryTweak -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "LaunchTo" -Value 1
Set-RegistryTweak -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "HideFileExt" -Value 0
Set-RegistryTweak -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "AutoCheckSelect" -Value 1

$tb = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced\TaskbarDeveloperSettings"
Set-RegistryTweak -Path $tb -Name "TaskbarEndTask" -Value 1

# verbose output on login and logout
Set-RegistryTweak -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "VerboseStatus" -Value 1

# Disable store searches and bing search in start menu
icacls "$Env:LocalAppData\Packages\Microsoft.WindowsStore_8wekyb3d8bbwe\LocalState\store.db" /deny Everyone:F
Set-RegistryTweak -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" -Name "BingSearchEnabled" -Value 0

# remove task view button
Set-RegistryTweak -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "ShowTaskViewButton" -Value 0

# Set list view on start menu
Set-RegistryTweak -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Start" -Name "AllAppsViewMode" -Value 2
if (-not (Test-Path "HKCU:\SOFTWARE\Policies\Microsoft\Windows\Explorer")) { New-Item -Path "HKCU:\SOFTWARE\Policies\Microsoft\Windows\Explorer" -Force | Out-Null }
Set-ItemProperty -Path "HKCU:\SOFTWARE\Policies\Microsoft\Windows\Explorer" -Name "HideRecommendedSection" -Value 1 -Type DWord

# Ensure the "All Apps" / "More Programs" list is NOT hidden (removes the restriction)
Remove-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" -Name "NoStartMenuMorePrograms" -ErrorAction SilentlyContinue

# Optimized Recall Check (Disable only, payload kept)
$recallFeature = Get-WindowsOptionalFeature -Online -FeatureName "Recall" -ErrorAction SilentlyContinue
if ($recallFeature -and $recallFeature.State -eq "Enabled") {
    Write-Host "Disabling Recall..." -ForegroundColor Yellow
    DISM /Online /Disable-Feature /FeatureName=Recall /NoRestart /Quiet
} else {
    Write-Host "Recall is already disabled." -ForegroundColor Green
}

# Security
Set-MpPreference -PUAProtection Enabled
$defender = "HKCU:\Software\Microsoft\Windows Defender\Reputation-based Protection"
Set-RegistryTweak -Path $defender -Name "EnableAppRepControl" -Value 1
Set-RegistryTweak -Path $defender -Name "BlockPUAApps" -Value 1
Get-AppxPackage *windowssecurity* | Reset-AppxPackage

# Dark Mode & Explorer Restart
Set-ItemProperty -Path HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize -Name AppsUseLightTheme -Value 0
Set-ItemProperty -Path HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize -Name SystemUsesLightTheme -Value 0
Stop-Process -Name "explorer" -Force -ErrorAction SilentlyContinue

#stop services (Optimized to skip if already stopped and disabled)
$servicesToStop = @("DiagTrack", "MapsBroker", "CscService")
foreach ($service in $servicesToStop) {
    $srv = Get-Service -Name $service -ErrorAction SilentlyContinue
    if ($srv) {
        if ($srv.StartType -ne 'Disabled' -or $srv.Status -eq 'Running') {
            Stop-Service -Name $service -Force -ErrorAction SilentlyContinue
            Set-Service -Name $service -StartupType Disabled
        }
    }
}

Get-Process *Widget* | Stop-Process -Force -ErrorAction SilentlyContinue

# Debloat Apps (Optimized via winget list local checks)
$Removals = @(
    "Copilot", "3D Viewer", "Cortana", "Feedback Hub", "Microsoft 365 (Office)", 
    "Films & TV", "maps", "Mail and Calendar", "Paint 3D", "skype", "Microsoft News", 
    "Microsoft To Do", "Microsoft Bing Search", "Power Automate", "Quick assist", 
    "Solitaire & Casual Games", "Sound Recorder", "Sticky Notes", "Weather", "Xbox", 
    "Microsoft Clipchamp", "MSN Weather", "microsoft 365 copilot", "McAfee Personal Security", 
    "Microsoft.Teams", "Microsoft Bing", "Get Help", "Dev Home", "Phone Link", 
    "Cross Device Experience Host", "Windows Web Experience Pack", "Widgets Platform Runtime", 
    "Xbox TCUI", "Game Bar", "Xbox Identity Provider", "Game Speech Window", "Start Experiences App"
)
foreach ($app in $Removals) { 
    $isInstalled = winget list --name $app --accept-source-agreements 2>$null | Select-String $app
    if ($isInstalled) {
        winget remove $app --accept-source-agreements | Out-Null
    }
}

# Optimized Feature Purge Block (Fully Uninstalled / Removed with Payload purges)
$FeaturesToRemove = @("MediaPlayback", "MSRDC-Infrastructure", "SMBDirect", "WorkFolders-Client")
foreach ($featureName in $FeaturesToRemove) {
    $feature = Get-WindowsOptionalFeature -Online -FeatureName $featureName -ErrorAction SilentlyContinue
    if ($feature -and $feature.State -ne "DisabledWithPayloadRemoved") {
        Write-Host "Uninstalling and purging payload for: $featureName..." -ForegroundColor Yellow
        DISM /Online /Disable-Feature /FeatureName:$featureName /Remove /NoRestart /Quiet
    }
}

# --- Telemetry Registry Tweaks (Optimized via Loop) ---
$RegistrySettings = @(
    @{ Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo"; Name = "Enabled"; Value = 0; Type = "DWord" },
    @{ Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Privacy"; Name = "TailoredExperiencesWithDiagnosticDataEnabled"; Value = 0; Type = "DWord" },
    @{ Path = "HKCU:\Software\Microsoft\Speech_OneCore\Settings\OnlineSpeechPrivacy"; Name = "HasAccepted"; Value = 0; Type = "DWord" },
    @{ Path = "HKCU:\Software\Microsoft\Input\TIPC"; Name = "Enabled"; Value = 0; Type = "DWord" },
    @{ Path = "HKCU:\Software\Microsoft\InputPersonalization"; Name = "RestrictImplicitInkCollection"; Value = 1; Type = "DWord" },
    @{ Path = "HKCU:\Software\Microsoft\InputPersonalization"; Name = "RestrictImplicitTextCollection"; Value = 1; Type = "DWord" },
    @{ Path = "HKCU:\Software\Microsoft\InputPersonalization\TrainedDataStore"; Name = "HarvestContacts"; Value = 0; Type = "DWord" },
    @{ Path = "HKCU:\Software\Microsoft\Personalization\Settings"; Name = "AcceptedPrivacyPolicy"; Value = 0; Type = "DWord" },
    @{ Path = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection"; Name = "AllowTelemetry"; Value = 0; Type = "DWord" },
    @{ Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"; Name = "Start_TrackProgs"; Value = 0; Type = "DWord" },
    @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System"; Name = "PublishUserActivities"; Value = 0; Type = "DWord" },
    @{ Path = "HKCU:\Software\Microsoft\Siuf\Rules"; Name = "NumberOfSIUFInPeriod"; Value = 0; Type = "DWord" }
)

foreach ($Reg in $RegistrySettings) {
    Set-RegistryTweak -Path $Reg.Path -Name $Reg.Name -Value $Reg.Value -Type $Reg.Type
}

#########################Myles CleanUp-Tool############################
Set-Location windowsinstaller
Get-ChildItem -Path .\Setup.exe -Recurse | Unblock-File
.\Setup.exe

#######################################################################

# Set-Cursor
Get-ChildItem -Path .\set-cursor.ps1 -Recurse | Unblock-File
.\set-cursor.ps1

###########################ohmyposh theme##############################
wt new-tab pwsh -Command "irm https://github.com/Myles-Mattlock/ohmyposh/raw/main/setup.ps1 | iex"

Set-Location ..
#######################################################################

# disable powershell7 telemetry
Write-Host "Disabling PowerShell 7 Telemetry..." -ForegroundColor Yellow

# Sets the environment variable globally at the Machine level
[Environment]::SetEnvironmentVariable('POWERSHELL_TELEMETRY_OPTOUT', '1', 'Machine')

# Updates the current running script session immediately so you don't have to restart the terminal
$env:POWERSHELL_TELEMETRY_OPTOUT = '1'

Write-Host "PowerShell 7 Telemetry disabled successfully." -ForegroundColor Green

# Remove specific PeriodInNanoSeconds property
Remove-ItemProperty -Path "HKCU:\Software\Microsoft\Siuf\Rules" -Name "PeriodInNanoSeconds" -ErrorAction SilentlyContinue

Write-Host "Telemetry tweaks applied (Skipped non-existent services)." -ForegroundColor Green

#Remove Edge (Optimized to skip folder scanning if main paths do not exist)
Write-Host "Removing Microsoft Edge..." -ForegroundColor Yellow

$EdgePaths = @(
    "${env:ProgramFiles(x86)}\Microsoft\Edge\Application",
    "${env:ProgramFiles}\Microsoft\Edge\Application"
)

$EdgeInstalled = $EdgePaths | Where-Object { Test-Path $_ }

if (-not $EdgeInstalled) {
    Write-Host "Microsoft Edge application directories not found. Already removed." -ForegroundColor Green
} else {
    $RegPath = "HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\Microsoft Edge"
    if (Test-Path $RegPath) {
        Set-ItemProperty -Path $RegPath -Name "NoRemove" -Value 0
    }

    $Executed = $false
    foreach ($Path in $EdgePaths) {
        if (Test-Path $Path) {
            $SetupExe = Get-ChildItem -Path $Path -Filter "setup.exe" -Recurse | Select-Object -First 1
            if ($SetupExe) {
                $Arguments = "--uninstall --system-level --verbose-logging --force-uninstall"
                Start-Process -FilePath $SetupExe.FullName -ArgumentList $Arguments -NoNewWindow -Wait
                Write-Host "Edge removal command executed successfully." -ForegroundColor Green
                $Executed = $true
                break
            }
        }
    }

    if (-not $Executed) {
        Write-Warning "Microsoft Edge uninstaller (setup.exe) was not found."
    }
}

Write-Host "`nDONE! Finalizing system..." -ForegroundColor Green
# setting original policy:
Set-ExecutionPolicy $originalPolicy -Scope LocalMachine -Force