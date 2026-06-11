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

# Run Updates
winget update --accept-source-agreements --accept-package-agreements
# --------------------------

Write-Host "System Tweaks & Debloat ---" -ForegroundColor Cyan

# Explorer & Taskbar
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "LaunchTo" -Value 1
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "HideFileExt" -Value 0
$tb = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced\TaskbarDeveloperSettings"
if (-not (Test-Path $tb)) { New-Item -Path $tb -Force | Out-Null }
Set-ItemProperty -Path $tb -Name "TaskbarEndTask" -Value 1

# verbose output on login and logout
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "VerboseStatus" -Value 1 -Type DWord

# Disable store searches and bing search in start menu
icacls "$Env:LocalAppData\Packages\Microsoft.WindowsStore_8wekyb3d8bbwe\LocalState\store.db" /deny Everyone:F
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" -Name "BingSearchEnabled" -Value 0 -Type DWord

# remove task view button
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "ShowTaskViewButton" -Value 0 -Type DWord

# Set list view on start menu
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Start" -Name "AllAppsViewMode" -Value 2 -Type DWord

# Ensure the "All Apps" / "More Programs" list is NOT hidden (removes the restriction)
Remove-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" -Name "NoStartMenuMorePrograms" -ErrorAction SilentlyContinue

#########################Myles CleanUp-Tool############################
.\Setup.exe
#######################################################################

# Disable Recall
DISM /Online /Disable-Feature /FeatureName=Recall /NoRestart

# Security
Set-MpPreference -PUAProtection Enabled
$defender = "HKCU:\Software\Microsoft\Windows Defender\Reputation-based Protection"
if (-not (Test-Path $defender)) { New-Item -Path $defender -Force | Out-Null }
Set-ItemProperty -Path $defender -Name "EnableAppRepControl" -Value 1
Set-ItemProperty -Path $defender -Name "BlockPUAApps" -Value 1
Get-AppxPackage *windowssecurity* | Reset-AppxPackage

# Dark Mode & Explorer Restart
Set-ItemProperty -Path HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize -Name AppsUseLightTheme -Value 0
Set-ItemProperty -Path HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize -Name SystemUsesLightTheme -Value 0
Stop-Process -Name "explorer" -Force -ErrorAction SilentlyContinue

# # Wallpaper
# mkdir C:\Windows\Web\Wallpaper\Myles
# $img = "WindowsInstaller\image.png"
# if (Test-Path $img) {
#     $dest = "C:\Windows\Web\Wallpaper\Myles\image.png"
#     Copy-Item -Path $img -Destination $dest -Force
#     Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name Wallpaper -Value $dest
#     rundll32.exe user32.dll, UpdatePerUserSystemParameters
# }

#stop services
$servicesToStop = @(
    "DiagTrack",
    "MapsBroker",
    "CscService"
)

foreach ($service in $servicesToStop) {
    Stop-Service -Name $service
    Set-Service -Name $service -StartupType Disabled
}

Get-Process *Widget* | Stop-Process -Force -ErrorAction SilentlyContinue

# Debloat
$Removals = @(
    "Copilot", 
    "3D Viewer", 
    "Cortana", 
    "Feedback Hub", 
    "Microsoft 365 (Office)",
    "Films & TV", 
    "maps", 
    "Mail and Calendar", 
    "Paint 3D", 
    "skype", 
    "Microsoft News",
    "Microsoft To Do", 
    "Microsoft Bing Search", 
    "Power Automate", 
    "Quick assist",
    "Solitaire & Casual Games", 
    "Sound Recorder", 
    "Sticky Notes", 
    "Weather", 
    "Xbox",
    "Microsoft Clipchamp", 
    "MSN Weather", 
    "microsoft 365 copilot", 
    "McAfee Personal Security",
    "Microsoft.Teams",
    "Microsoft Bing",
    "Get Help",
    "Dev Home",
    "Phone Link",
    "Cross Device Experience Host",
    "Windows Web Experience Pack",
    "Widgets Platform Runtime",
    "Xbox TCUI",
    "Game Bar",
    "Xbox Identity Provider",
    "Game Speech Window",
    "Start Experiences App"
)
foreach ($app in $Removals) { winget remove $app --accept-source-agreements }


#disable telmentry
# --- Registry Tweaks ---
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
    if (-not (Test-Path $Reg.Path)) {
        New-Item -Path $Reg.Path -Force | Out-Null
    }
    Set-ItemProperty -Path $Reg.Path -Name $Reg.Name -Value $Reg.Value -Type $Reg.Type
}

# Remove specific PeriodInNanoSeconds property
Remove-ItemProperty -Path "HKCU:\Software\Microsoft\Siuf\Rules" -Name "PeriodInNanoSeconds" -ErrorAction SilentlyContinue

Write-Host "Telemetry tweaks applied (Skipped non-existent services)." -ForegroundColor Green

#Remove Edge
# Ensure script is running as Administrator
Write-Host "Removing Microsoft Edge..." -ForegroundColor Yellow

# 1. Unblock the uninstaller by modifying the registry
$RegPath = "HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\Microsoft Edge"
if (Test-Path $RegPath) {
    Set-ItemProperty -Path $RegPath -Name "NoRemove" -Value 0
}

# 2. Look for setup.exe in standard Edge directories
$EdgePaths = @(
    "${env:ProgramFiles(x86)}\Microsoft\Edge\Application",
    "${env:ProgramFiles}\Microsoft\Edge\Application"
)

$Executed = $false

foreach ($Path in $EdgePaths) {
    if (Test-Path $Path) {
        # Find the setup.exe file inside the version-numbered folder
        $SetupExe = Get-ChildItem -Path $Path -Filter "setup.exe" -Recurse | Select-Object -First 1
        if ($SetupExe) {
            $Arguments = "--uninstall --system-level --verbose-logging --force-uninstall"
            
            # Run the uninstaller and wait for it to complete
            Start-Process -FilePath $SetupExe.FullName -ArgumentList $Arguments -Wait -NoNewWindow
            Write-Host "Edge removal command executed successfully." -ForegroundColor Green
            $Executed = $true
            break
        }
    }
}

if (-not $Executed) {
    Write-Warning "Microsoft Edge uninstaller (setup.exe) was not found. It may already be removed."
}

Write-Host "`nDONE! Finalizing system..." -ForegroundColor Green

# setting original policy:
Set-ExecutionPolicy $originalPolicy -Scope LocalMachine -Force