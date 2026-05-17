#######################################################################
# --- 1. SINGLE INSTANCE LOCK ---
#######################################################################
# This prevents the "Twin Window" bug. Only one instance can exist.
$Mutex = New-Object System.Threading.Mutex($false, "Global\MylesUpdateToolLock")
if (!$Mutex.WaitOne(0)) {
    exit
}

#######################################################################
# --- 2. PERSISTENCE & ADMIN LOGIC (EXE VERSION) ---
#######################################################################
$Mutex = New-Object System.Threading.Mutex($false, "Global\MylesInstallExeLock")
if (!$Mutex.WaitOne(0)) { exit }

$StateFile = "$env:TEMP\UpdateScriptState.txt"

# Get the actual path of the install.exe file
$ExePath = [System.Diagnostics.Process]::GetCurrentProcess().MainModule.FileName
$WorkingDir = Split-Path -Parent $ExePath

# Ensure the EXE works out of its own folder
Set-Location $WorkingDir

function Set-State {
    param([int]$Step)
    $Step | Out-File -FilePath $StateFile -Force
}

function Clear-Persistence {
    Remove-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\RunOnce" -Name "ResumeUpdateScript" -ErrorAction SilentlyContinue
    if (Test-Path $StateFile) { Remove-Item $StateFile -Force }
}

# --- ADMIN CHECK ---
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    # Launch the EXE directly, no powershell arguments needed
    Start-Process "$ExePath" -Verb RunAs
    exit
}

# Determine Current Step
$CurrentStep = 0
if (Test-Path $StateFile) { $CurrentStep = Get-Content $StateFile }

#######################################################################
# --- 3. EXECUTION PHASES ---
#######################################################################

switch ($CurrentStep) {
    
    # PHASE 0: UPDATES & REBOOT
    0 {
        Write-Host "--- PHASE 0: Configuring Update Policies & Windows Updates ---" -ForegroundColor Cyan
        
        # Check if the sub-script exists before running
        $originalPolicy = Get-ExecutionPolicy

        # 2. Set it to RemoteSigned
        Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope LocalMachine -Force
        
        if (Test-Path ".\WindowsInstaller\AddWifi.ps1") {
            Write-Host "--- Adding Wifi connection -Home wifi ---" -ForegroundColor Cyan
            .\WindowsInstaller\AddWifi.ps1
            Start-Sleep -Seconds 15
        }

        # Registry Update Policies
        $WU = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate"
        if (-not (Test-Path $WU)) { New-Item -Path $WU -Force | Out-Null }
        Set-ItemProperty -Path $WU -Name "DeferFeatureUpdates" -Value 1
        Set-ItemProperty -Path $WU -Name "DeferFeatureUpdatesPeriodInDays" -Value 365
        Set-ItemProperty -Path $WU -Name "DeferQualityUpdates" -Value 1
        Set-ItemProperty -Path $WU -Name "DeferQualityUpdatesPeriodInDays" -Value 4
        Set-ItemProperty -Path $WU -Name "EnableOptionalUpdates" -Value 0
        gpupdate /force

        # Dependencies
        Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.208 -Force -Scope CurrentUser
        Install-Module PSWindowsUpdate -Force -Scope CurrentUser
        
        # Run Updates
        Import-Module PSWindowsUpdate
        Install-WindowsUpdate -ForceDownload -ForceInstall -Confirm:$false -IgnoreReboot
        winget update --all --accept-source-agreements --accept-package-agreements

        # SETUP RESUME
        Set-State 1
        
        # FIX: Point directly to the EXE path in quotes. 
        # No 'powershell.exe' or '-File' needed for install.exe
        $RegistryPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\RunOnce"

        # Check if the RunOnce key exists; if not, create it
        if (-not (Test-Path $RegistryPath)) {
            New-Item -Path $RegistryPath -Force | Out-Null
        }

        # Now safe to set the property
        Set-ItemProperty -Path $RegistryPath -Name "ResumeUpdateScript" -Value $RunCmd
        
        Set-ExecutionPolicy $originalPolicy -Scope LocalMachine -Force
        Write-Host "`nRebooting to continue script..." -ForegroundColor Red
        Start-Sleep -Seconds 5
        Restart-Computer -Force
        exit
    }

    # PHASE 1: UI, DEBLOAT & INSTALLS
    1 {
        # FIRST ACTION: Wipe the registry key so no duplicates can trigger
        Clear-Persistence

        Write-Host "--- PHASE 1: Resuming - System Tweaks & Debloat ---" -ForegroundColor Cyan
        
        # Explorer & Taskbar
        Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "LaunchTo" -Value 1
        Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "HideFileExt" -Value 0
        $tb = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced\TaskbarDeveloperSettings"
        if (-not (Test-Path $tb)) { New-Item -Path $tb -Force | Out-Null }
        Set-ItemProperty -Path $tb -Name "TaskbarEndTask" -Value 1

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
            "Microsoft.Teams"
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

        # --- Invoke Scripts ---

        # Disable (Connected User Experiences and Telemetry) Service
        Stop-Service -Name diagtrack -ErrorAction SilentlyContinue
        Set-Service -Name diagtrack -StartupType Disabled -ErrorAction SilentlyContinue

        # Disable (Windows Error Reporting Manager) Service
        Stop-Service -Name wermgr -ErrorAction SilentlyContinue
        Set-Service -Name wermgr -StartupType Disabled -ErrorAction SilentlyContinue

        # Remove specific PeriodInNanoSeconds property
        Remove-ItemProperty -Path "HKCU:\Software\Microsoft\Siuf\Rules" -Name "PeriodInNanoSeconds" -ErrorAction SilentlyContinue

        Write-Host "Telemetry tweaks applied (Skipped non-existent services)." -ForegroundColor Green
                
        
        # Installs
        .\windowsinstalle\ohmyposh.ps1
        winget install Google.Chrome bitwarden.bitwarden KDE.Kdenlive Valve.Steam --accept-source-agreements

        # Office
        if (Test-Path ".\WindowsInstaller\OfficeSetup.exe") {
            Write-Host "Starting Office Setup..." -ForegroundColor Yellow
            Start-Process -FilePath ".\WindowsInstaller\OfficeSetup.exe" -Wait
        }

        Write-Host "`nDONE! Finalizing system..." -ForegroundColor Green
        Start-Sleep -Seconds 6000
        Restart-Computer -Force
    }
}