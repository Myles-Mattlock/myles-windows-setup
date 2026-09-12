#requires -Version 5.1

$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator
)
if (-not $isAdmin) {
    Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs -WindowStyle Hidden
    exit
}

Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase, System.Windows.Forms

Add-Type -MemberDefinition @"
    [DllImport("dwmapi.dll")]
    public static extern int DwmSetWindowAttribute(IntPtr hwnd, int attr, ref int attrValue, int attrSize);
"@ -Name "DwmApi" -Namespace "Win32" | Out-Null

$script:Root = Split-Path -Parent $PSCommandPath
$script:BrushConverter = [System.Windows.Media.BrushConverter]::new()
$script:AppVersion = '1.0.0'

[xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Myles Mattlock WinTool" Height="920" Width="1000"
        WindowStartupLocation="CenterScreen" Background="#1E1E1E" Foreground="#FFFFFF">
    <Window.Resources>
        <Style TargetType="Button">
            <Setter Property="Background" Value="#007ACC"/>
            <Setter Property="Foreground" Value="#FFFFFF"/>
            <Setter Property="BorderThickness" Value="0"/>
            <Setter Property="Padding" Value="16,9"/>
            <Setter Property="Margin" Value="0,0,8,8"/>
            <Setter Property="Cursor" Value="Hand"/>
        </Style>
        <Style TargetType="CheckBox">
            <Setter Property="Foreground" Value="#FFFFFF"/>
            <Setter Property="Margin" Value="0,0,0,10"/>
            <Setter Property="FontSize" Value="14"/>
        </Style>
        <Style TargetType="TabItem">
            <Setter Property="Padding" Value="18,10"/>
            <Setter Property="FontSize" Value="14"/>
        </Style>
        <Style x:Key="CleanupActionButton" TargetType="Button">
            <Setter Property="Background" Value="#007ACC"/>
            <Setter Property="Foreground" Value="#FFFFFF"/>
            <Setter Property="FontWeight" Value="Bold"/>
            <Setter Property="BorderThickness" Value="0"/>
            <Setter Property="Padding" Value="16,9"/>
        </Style>
    </Window.Resources>
    <Grid Margin="24">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="180"/>
        </Grid.RowDefinitions>
        <Border Grid.Row="0" Background="#252526" CornerRadius="8" Padding="20" Margin="0,0,0,20">
            <Grid>
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="*"/>
                    <ColumnDefinition Width="Auto"/>
                </Grid.ColumnDefinitions>
                <StackPanel Grid.Column="0" VerticalAlignment="Center">
                    <TextBlock Text="Myles Mattlock WinTool" FontSize="24" FontWeight="Bold" Foreground="#FFFFFF"/>
                    <TextBlock Text="Install, customize, and maintain Windows from one focused workspace" FontSize="14" Foreground="#AAAAAA" Margin="0,4,0,0"/>
                </StackPanel>
                <StackPanel Grid.Column="1" Orientation="Horizontal" VerticalAlignment="Center">
                    <TextBlock x:Name="HeaderVersion" Text="v1.0.0" Foreground="#888888" FontSize="16" FontWeight="SemiBold" VerticalAlignment="Center" Margin="0,0,20,0"/>
                    <Image x:Name="HeaderLogo" Width="90" Height="76" Stretch="Uniform"/>
                </StackPanel>
            </Grid>
        </Border>
        <TabControl x:Name="MainTabs" Grid.Row="1" Background="#252526" BorderThickness="0">
            <TabItem Header="Info" Foreground="#000000">
                <ScrollViewer Padding="20" VerticalScrollBarVisibility="Auto">
                    <StackPanel>
                        <TextBlock Text="System Information" Foreground="#00A8E8" FontWeight="Bold" FontSize="12" Margin="0,0,0,14"/>
                        <Border Background="#2D2D30" Padding="14" Margin="0,0,0,12">
                            <StackPanel>
                                <TextBlock Text="WINDOWS VERSION" FontSize="11" FontWeight="Bold" Foreground="#888888"/>
                                <TextBlock x:Name="InfoWindowsLoading" Text="Loading..." Foreground="#888888" Margin="0,4,0,0"/>
                                <TextBlock x:Name="InfoWindowsVersion" Text="" Foreground="#FFFFFF" FontSize="16" FontWeight="Bold" Margin="0,4,0,0"/>
                            </StackPanel>
                        </Border>
                        <TextBlock Text="DRIVE STATUS" FontSize="11" FontWeight="Bold" Foreground="#888888" Margin="0,4,0,8"/>
                        <StackPanel x:Name="InfoDriveStatus">
                            <TextBlock x:Name="InfoDriveLoading" Text="Loading..." Foreground="#888888"/>
                        </StackPanel>
                    </StackPanel>
                </ScrollViewer>
            </TabItem>
            <TabItem Header="Install / Remove Apps">
                <ScrollViewer Padding="20" VerticalScrollBarVisibility="Auto">
                    <StackPanel>
                        <TextBlock Text="App Library" Foreground="#00A8E8" FontWeight="Bold" FontSize="12" Margin="0,0,0,14"/>
                        <UniformGrid Columns="3">
                            <CheckBox x:Name="InstallPowerShell" Content="PowerShell 7"/>
                            <CheckBox x:Name="InstallOperaGx" Content="Opera GX"/>
                            <CheckBox x:Name="InstallChrome" Content="Google Chrome"/>
                            <CheckBox x:Name="InstallFirefox" Content="Mozilla Firefox"/>
                            <CheckBox x:Name="InstallDocker" Content="Docker Desktop"/>
                            <CheckBox x:Name="InstallGithubDesktop" Content="GitHub Desktop"/>
                            <CheckBox x:Name="InstallTeams" Content="Microsoft Teams"/>
                            <CheckBox x:Name="InstallJabra" Content="Jabra Direct"/>
                            <CheckBox x:Name="Install7zip" Content="7-Zip"/>
                            <CheckBox x:Name="InstallVscode" Content="Visual Studio Code"/>
                            <CheckBox x:Name="InstallOffice" Content="Microsoft 365"/>
                            <CheckBox x:Name="InstallHwmonitor" Content="HWMonitor"/>
                            <CheckBox x:Name="InstallNotepadPlus" Content="Notepad++"/>
                            <CheckBox x:Name="InstallPostman" Content="Postman"/>
                            <CheckBox x:Name="InstallGit" Content="Git"/>
                            <CheckBox x:Name="InstallWsl" Content="WSL"/>
                            <CheckBox x:Name="InstallPowertoys" Content="PowerToys"/>
                        </UniformGrid>
                        <TextBlock Text="Select apps to install or uninstall" Foreground="#888888" Margin="0,8,0,8"/>
                        <WrapPanel>
                            <Button x:Name="InstallSelected" Content="Install selected apps" Height="37" HorizontalAlignment="Left" VerticalAlignment="Top" Margin="0,0,8,0"/>
                            <Button x:Name="UninstallSelected" Content="Uninstall selected apps" Width="180" Background="#A83D3D" HorizontalAlignment="Left" VerticalAlignment="Top"/>
                        </WrapPanel>
                    </StackPanel>
                </ScrollViewer>
            </TabItem>
            <TabItem Header="Customization">
                <ScrollViewer Padding="20" VerticalScrollBarVisibility="Auto">
                    <StackPanel>
                        <TextBlock Text="Windows Preferences" Foreground="#00A8E8" FontWeight="Bold" FontSize="12" Margin="0,0,0,14"/>
                        <CheckBox x:Name="ShowFileExtensions" Content="Show file extensions" IsChecked="True"/>
                        <CheckBox x:Name="ShowTaskView" Content="Show Task View button" IsChecked="True"/>
                        <CheckBox x:Name="HideRecommended" Content="Hide Recommended section in Start" IsChecked="True"/>
                        <CheckBox x:Name="DarkMode" Content="Use dark mode" IsChecked="True"/>
                        <CheckBox x:Name="DefenderPua" Content="Enable potentially unwanted app protection" IsChecked="True"/>
                        <Button x:Name="ApplyCustomization" Content="Apply customization" HorizontalAlignment="Left"/>
                        <Separator Margin="0,18,0,12"/>
                        <TextBlock Text="Debloat" FontSize="18" FontWeight="Bold" Margin="0,0,0,8"/>
                        <CheckBox x:Name="KeepTeams" Content="Keep Microsoft Teams" IsChecked="False"/>
                        <Button x:Name="RunDebloat" Content="Run debloat" Background="#A83D3D" HorizontalAlignment="Left"/>
                        <TextBlock Text="Changes are applied to the current user unless Windows requires administrator access." Foreground="#888888" TextWrapping="Wrap" Margin="0,8,0,0"/>
                    </StackPanel>
                </ScrollViewer>
            </TabItem>
            <TabItem Header="Cleanup">
                <ScrollViewer VerticalScrollBarVisibility="Auto" HorizontalScrollBarVisibility="Disabled">
                <Grid Margin="0,0,20,20">
                    <Grid.RowDefinitions><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/></Grid.RowDefinitions>
                    <Border Grid.Row="0" Background="#252526" CornerRadius="8" Padding="20" Margin="0,0,0,15">
                        <Grid><Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions><StackPanel><TextBlock Text="System Cleanup" Foreground="#00A8E8" FontWeight="Bold" FontSize="12" Margin="0,0,0,0"/><TextBlock Text="Optimize storage, system files, and component health" FontSize="14" Foreground="#AAAAAA" Margin="0,0,0,0"/></StackPanel></Grid>
                    </Border>
                    <Border Grid.Row="2" Background="#252526" CornerRadius="6" Padding="12" Margin="0,0,0,15">
                        <StackPanel><TextBlock Text="SELECT TASKS TO RUN" FontSize="11" FontWeight="Bold" Foreground="#888888" Margin="0,0,0,8"/><WrapPanel Height="30" Margin="0,0,0,8"><TextBlock Text="PROFILES:" FontSize="11" FontWeight="Bold" Foreground="#888888" VerticalAlignment="Center" Margin="0,0,10,0"/><Button x:Name="DefaultProfile" Content="Default" Width="80" Height="26" Padding="4,0" Background="#007ACC" FontSize="11" Margin="0,0,6,0"/><Button x:Name="ServerProfile" Content="Server Cleanup" Width="105" Height="26" Padding="4,0" Background="#2D2D30" Foreground="#AAAAAA" FontSize="11" Margin="0,0,6,0"/><Button x:Name="CustomProfile" Content="Custom" Width="80" Height="26" Padding="4,0" Background="#2D2D30" Foreground="#AAAAAA" FontSize="11"/></WrapPanel><WrapPanel><CheckBox x:Name="CleanupTemp" Content="Clear Temp Files &amp; System Logs" IsChecked="True" Margin="0,0,15,5"/><CheckBox x:Name="CleanupRecycle" Content="Empty Recycle Bin" IsChecked="True" Margin="0,0,15,5"/><CheckBox x:Name="CleanupCleanmgr" Content="Run Disk Cleanup Utility" IsChecked="True" Margin="0,0,15,5"/><CheckBox x:Name="CleanupDns" Content="Flush DNS Cache" IsChecked="True" Margin="0,0,15,5"/><CheckBox x:Name="CleanupDism" Content="DISM Component Store Cleanup" IsChecked="True" Margin="0,0,15,5"/></WrapPanel></StackPanel>
                    </Border>
                    <Border Grid.Row="3" Background="#2D2D30" CornerRadius="6" Padding="15" Margin="0,0,0,0"><Grid><Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions><StackPanel><TextBlock Text="TOTAL STORAGE RECLAIMED" FontSize="11" FontWeight="Bold" Foreground="#888888"/><TextBlock Text="Space freed during the current optimization session" FontSize="12" Foreground="#AAAAAA" Margin="0,2,0,0"/></StackPanel><TextBlock Grid.Column="1" Text="0 MB" FontSize="22" FontWeight="Bold" Foreground="#00FF66" VerticalAlignment="Center"/></Grid></Border>
                    <Grid Grid.Row="4" Height="18" Margin="0,15,0,15"><ProgressBar x:Name="CleanupProgress" Value="0" Maximum="100" Background="#2D2D30" Foreground="#007ACC"/><TextBlock x:Name="CleanupProgressPercent" Text="0%" Foreground="#FFFFFF" FontSize="11" FontWeight="Bold" HorizontalAlignment="Center" VerticalAlignment="Center"/></Grid>
                    <Grid Grid.Row="5"><Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions><TextBlock x:Name="CleanupStatus" Text="Ready to start cleanup." Foreground="#AAAAAA" FontSize="14" VerticalAlignment="Center"/><Button x:Name="StartCleanup" Grid.Column="1" Content="Start Cleanup" Width="160" Height="42" Style="{StaticResource CleanupActionButton}"/></Grid>
                </Grid>
                </ScrollViewer>
            </TabItem>
        </TabControl>
        <Border Grid.Row="2" Background="#0C0C0C" BorderBrush="#333333" BorderThickness="1" Padding="12" Margin="0,16,0,0">
            <ScrollViewer x:Name="LogScroll" VerticalScrollBarVisibility="Auto">
                <TextBox x:Name="Log" Background="Transparent" Foreground="#00FF66" BorderThickness="0" FontFamily="Consolas" IsReadOnly="True" TextWrapping="Wrap"/>
            </ScrollViewer>
        </Border>
    </Grid>
</Window>
"@

$reader = New-Object System.Xml.XmlNodeReader $xaml
$window = [Windows.Markup.XamlReader]::Load($reader)
@('HeaderVersion','HeaderLogo','InfoWindowsVersion','InfoWindowsLoading','InfoDriveStatus','InfoDriveLoading','InstallPowerShell','InstallOperaGx','InstallChrome','InstallFirefox','InstallDocker','InstallGithubDesktop','InstallTeams','InstallJabra','Install7zip','InstallVscode','InstallOffice','InstallHwmonitor','InstallNotepadPlus','InstallPostman','InstallGit','InstallWsl','InstallPowertoys','ShowFileExtensions','ShowTaskView','HideRecommended','DarkMode','DefenderPua','InstallSelected','UninstallSelected','ApplyCustomization','KeepTeams','RunDebloat','DefaultProfile','ServerProfile','CustomProfile','CleanupTemp','CleanupRecycle','CleanupCleanmgr','CleanupDns','CleanupDism','CleanupStatus','CleanupProgress','CleanupProgressPercent','StartCleanup','Log','LogScroll') | ForEach-Object {
    Set-Variable -Name $_ -Value $window.FindName($_)
}

$removalCatalog = @(
    'Copilot', '3D Viewer', 'Cortana', 'Feedback Hub', 'Microsoft 365 (Office)',
    'Films & TV', 'maps', 'Mail and Calendar', 'Paint 3D', 'skype', 'Microsoft News',
    'Microsoft To Do', 'Microsoft Bing Search', 'Power Automate', 'Quick assist',
    'Solitaire & Casual Games', 'Sound Recorder', 'Sticky Notes', 'Weather', 'Xbox',
    'Microsoft Clipchamp', 'MSN Weather', 'microsoft 365 copilot', 'McAfee Personal Security',
    'Microsoft.Teams', 'Microsoft Bing', 'Get Help', 'Dev Home', 'Phone Link',
    'Cross Device Experience Host', 'Windows Web Experience Pack', 'Widgets Platform Runtime',
    'Xbox TCUI', 'Game Bar', 'Xbox Identity Provider', 'Game Speech Window', 'Start Experiences App'
)
function Write-Log([string]$Message) {
    $Log.AppendText("[$(Get-Date -Format 'HH:mm:ss')] $Message`r`n")
    $Log.UpdateLayout()
    $Log.ScrollToEnd()
    $LogScroll.UpdateLayout()
    $LogScroll.ScrollToEnd()
}

function Invoke-Winget([string]$Action, [string]$PackageId, [string]$DisplayName, [switch]$ByName) {
    Write-Log "$Action $DisplayName..."
    try {
        $selector = if ($ByName) { @('--name', $PackageId) } else { @('--id', $PackageId, '--exact') }
        $agreementArguments = if ($Action -eq 'install') {
            @('--accept-source-agreements', '--accept-package-agreements')
        } else {
            @('--accept-source-agreements')
        }
        $wingetArguments = @($Action) + @($selector) + @($agreementArguments)
        & winget @wingetArguments 2>&1 | ForEach-Object { Write-Log ([string]$_) }
        Write-Log "$DisplayName finished with exit code $LASTEXITCODE."
    } catch { Write-Log "Could not run winget for ${DisplayName}: $($_.Exception.Message)" }
}

function Get-AppItems {
    @(
        @{ Check = $InstallPowerShell; Id = 'Microsoft.PowerShell'; Name = 'PowerShell 7' },
        @{ Check = $InstallOperaGx; Id = 'Opera.OperaGX'; Name = 'Opera GX' },
        @{ Check = $InstallChrome; Id = 'Google.Chrome'; Name = 'Google Chrome' },
        @{ Check = $InstallFirefox; Id = 'Mozilla.Firefox'; Name = 'Mozilla Firefox' },
        @{ Check = $InstallDocker; Id = 'Docker.DockerDesktop'; Name = 'Docker Desktop' },
        @{ Check = $InstallGithubDesktop; Id = 'GitHub.GitHubDesktop'; Name = 'GitHub Desktop' },
        @{ Check = $InstallTeams; Id = 'Microsoft.Teams'; Name = 'Microsoft Teams' },
        @{ Check = $InstallJabra; Id = 'Jabra.Direct'; Name = 'Jabra Direct' },
        @{ Check = $Install7zip; Id = '7zip.7zip'; Name = '7-Zip' },
        @{ Check = $InstallVscode; Id = 'Microsoft.VisualStudioCode'; Name = 'Visual Studio Code' },
        @{ Check = $InstallOffice; Id = 'Microsoft.Office'; Name = 'Microsoft 365' },
        @{ Check = $InstallHwmonitor; Id = 'CPUID.HWMonitor'; Name = 'HWMonitor' },
        @{ Check = $InstallNotepadPlus; Id = 'Notepad++.Notepad++'; Name = 'Notepad++' },
        @{ Check = $InstallPostman; Id = 'Postman.Postman'; Name = 'Postman' },
        @{ Check = $InstallGit; Id = 'Git.Git'; Name = 'Git' },
        @{ Check = $InstallWsl; Id = 'Microsoft.WSL'; Name = 'WSL' },
        @{ Check = $InstallPowertoys; Id = 'Microsoft.PowerToys'; Name = 'PowerToys' }
    )
}

$appItems = @(Get-AppItems)
function Initialize-AppItems {
    foreach ($item in $appItems) {
        try {
            $item.Installed = (& winget.exe list --id $item.Id --exact --accept-source-agreements 2>$null | Out-String) -match [regex]::Escape($item.Id)
        } catch { $item.Installed = $false }
        if ($item.Installed) {
            $item.Check.Content = "$($item.Name) (installed)"
        }
        $item.Check.IsChecked = $false
    }
}

function Get-InfoSmartctlData([int]$DiskIndex) {
    $smartctlPath = Get-Command 'smartctl.exe' -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source
    if (-not $smartctlPath) {
        foreach ($path in @((Join-Path $script:Root 'smartctl.exe'), 'C:\Program Files\smartmontools\bin\smartctl.exe', 'C:\Program Files (x86)\smartmontools\bin\smartctl.exe')) {
            if (Test-Path -LiteralPath $path) { $smartctlPath = $path; break }
        }
    }
    if (-not $smartctlPath) { return $null }
    try {
        $output = & $smartctlPath '-j' '-a' "/dev/pd$DiskIndex" 2>$null | Out-String
        if (-not [string]::IsNullOrWhiteSpace($output)) { return ($output | ConvertFrom-Json) }
    } catch {}
    return $null
}

function Update-InfoPage {
    try {
        $os = Get-CimInstance Win32_OperatingSystem -ErrorAction Stop
        $displayVersion = (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' -ErrorAction SilentlyContinue).DisplayVersion
        $version = if ($displayVersion) { $displayVersion } else { $os.Version }
        $InfoWindowsVersion.Text = "$($os.Caption) $version (Build $($os.BuildNumber))"
    } catch { $InfoWindowsVersion.Text = 'Unable to read Windows version.' }
    $InfoWindowsLoading.Visibility = 'Collapsed'

    $InfoDriveLoading.Visibility = 'Visible'
    $InfoDriveStatus.Children.Clear()
    try {
        $physicalDisks = @(Get-PhysicalDisk -ErrorAction SilentlyContinue)
        $fixedDrives = @([System.IO.DriveInfo]::GetDrives() | Where-Object { $_.DriveType -eq 'Fixed' -and $_.IsReady })
        foreach ($drive in $fixedDrives) {
            $disk = $null
            try {
                $partition = Get-Partition -DriveLetter $drive.Name.Substring(0, 1) -ErrorAction SilentlyContinue
                if ($partition) { $disk = $physicalDisks | Where-Object { $_.DeviceId -eq $partition.DiskNumber } | Select-Object -First 1 }
            } catch {}

            $health = 'N/A'
            $healthColor = '#888888'
            if ($disk) {
                $json = Get-InfoSmartctlData -DiskIndex $disk.DeviceId
                if ($json -and $null -ne $json.nvme_smart_health_information_log.percentage_used) {
                    $healthValue = 100 - [int]$json.nvme_smart_health_information_log.percentage_used
                    $health = "$healthValue% Health"
                    $healthColor = if ($healthValue -lt 70) { '#F87171' } elseif ($healthValue -lt 90) { '#FACC15' } else { '#4ADE80' }
                } elseif ($json -and $json.smart_status.passed -eq $true) {
                    $health = '100% Health'; $healthColor = '#4ADE80'
                } elseif ($disk.HealthStatus) {
                    $health = [string]$disk.HealthStatus
                    $healthColor = if ($health -eq 'Healthy') { '#4ADE80' } else { '#FACC15' }
                }
            }

            $row = New-Object System.Windows.Controls.Grid
            $row.Background = '#2D2D30'; $row.Padding = New-Object System.Windows.Thickness(12, 10, 12, 10); $row.Margin = New-Object System.Windows.Thickness(0, 0, 0, 8)
            $label = New-Object System.Windows.Controls.TextBlock
                $label.Text = "$($drive.Name.TrimEnd('\'))  ($([math]::Round($drive.TotalSize / 1GB, 1)) GB)"; $label.Foreground = '#FFFFFF'; $label.FontSize = 14; $label.VerticalAlignment = 'Center'
            $status = New-Object System.Windows.Controls.TextBlock
            $status.Text = $health; $status.Foreground = $healthColor; $status.FontWeight = 'Bold'; $status.FontSize = 14; $status.HorizontalAlignment = 'Right'; $status.VerticalAlignment = 'Center'
            [void]$row.Children.Add($label); [void]$row.Children.Add($status)
            [void]$InfoDriveStatus.Children.Add($row)
        }
        if ($fixedDrives.Count -eq 0) { $InfoDriveStatus.Children.Add((New-Object System.Windows.Controls.TextBlock -Property @{ Text = 'No fixed drives found.'; Foreground = '#888888' })) }
    } catch {
        $fixedDrives = @([System.IO.DriveInfo]::GetDrives() | Where-Object { $_.DriveType -eq 'Fixed' -and $_.IsReady })
        foreach ($drive in $fixedDrives) {
            $row = New-Object System.Windows.Controls.Grid
            $row.Background = '#2D2D30'; $row.Padding = New-Object System.Windows.Thickness(12, 10, 12, 10); $row.Margin = New-Object System.Windows.Thickness(0, 0, 0, 8)
            $label = New-Object System.Windows.Controls.TextBlock
            $label.Text = "$($drive.Name.TrimEnd('\'))  ($([math]::Round($drive.TotalSize / 1GB, 1)) GB)"; $label.Foreground = '#FFFFFF'; $label.FontSize = 14
            $status = New-Object System.Windows.Controls.TextBlock
            $status.Text = 'N/A'; $status.Foreground = '#888888'; $status.FontWeight = 'Bold'; $status.FontSize = 14; $status.HorizontalAlignment = 'Right'
            [void]$row.Children.Add($label); [void]$row.Children.Add($status)
            [void]$InfoDriveStatus.Children.Add($row)
        }
        if ($fixedDrives.Count -eq 0) { $InfoDriveStatus.Children.Add((New-Object System.Windows.Controls.TextBlock -Property @{ Text = 'No fixed drives found.'; Foreground = '#888888' })) }
    }
    $InfoDriveLoading.Visibility = 'Collapsed'
}

function Start-AppOperation([string]$Action) {
    $selectedItems = if ($Action -eq 'install') {
        @($appItems | Where-Object { $_.Check.IsChecked -and -not $_.Installed })
    } else {
        @($appItems | Where-Object { $_.Check.IsChecked -and $_.Installed })
    }
    if ($selectedItems.Count -eq 0) { Write-Log "No apps to $Action."; return }
    $InstallSelected.IsEnabled = $false
    $UninstallSelected.IsEnabled = $false
    $installLogQueue = [System.Collections.Concurrent.ConcurrentQueue[string]]::new()
    $installFinishedQueue = [System.Collections.Concurrent.ConcurrentQueue[bool]]::new()
    $installWorker = {
        param($Apps, $Action, $HelperPath, $LogQueue, $FinishedQueue)
        foreach ($item in $Apps) {
            $LogQueue.Enqueue("$Action $($item.Name)...")
            $outputPath = Join-Path $env:TEMP "MylesMattlock-winget-$([guid]::NewGuid()).log"
            $resultPath = Join-Path $env:TEMP "MylesMattlock-winget-$([guid]::NewGuid()).result"
            $taskName = "MylesMattlock-Winget-$([guid]::NewGuid())"
            try {
                $arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$HelperPath`" -Action $Action -PackageId `"$($item.Id)`" -OutputPath `"$outputPath`" -ResultPath `"$resultPath`""
                $taskAction = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument $arguments
                $taskTrigger = New-ScheduledTaskTrigger -Once -At (Get-Date).AddMinutes(1)
                $taskPrincipal = New-ScheduledTaskPrincipal -UserId ([System.Security.Principal.WindowsIdentity]::GetCurrent().Name) -LogonType Interactive -RunLevel Limited
                Register-ScheduledTask -TaskName $taskName -Action $taskAction -Trigger $taskTrigger -Principal $taskPrincipal -Force | Out-Null
                Start-ScheduledTask -TaskName $taskName
                $lineCount = 0
                do {
                    Start-Sleep -Milliseconds 100
                    if (Test-Path -LiteralPath $outputPath) {
                        $lines = @(Get-Content -LiteralPath $outputPath -ErrorAction SilentlyContinue)
                        while ($lineCount -lt $lines.Count) {
                            $LogQueue.Enqueue([string]$lines[$lineCount])
                            $lineCount++
                        }
                    }
                } while (-not (Test-Path -LiteralPath $resultPath))
                $exitCode = [int](Get-Content -LiteralPath $resultPath -Raw)
                $LogQueue.Enqueue("$($item.Name) finished with exit code $exitCode.")
            } catch { $LogQueue.Enqueue("Could not $Action $($item.Name): $($_.Exception.Message)") }
            finally {
                Unregister-ScheduledTask -TaskName $taskName -Confirm:$false -ErrorAction SilentlyContinue
                Remove-Item -LiteralPath $outputPath, $resultPath -Force -ErrorAction SilentlyContinue
            }
        }
        $FinishedQueue.Enqueue($true)
    }
    $installRunspace = [runspacefactory]::CreateRunspace()
    $installRunspace.Open()
    $installPowerShell = [powershell]::Create()
    $installPowerShell.Runspace = $installRunspace
    [void]$installPowerShell.AddScript($installWorker)
    [void]$installPowerShell.AddArgument($selectedItems)
    [void]$installPowerShell.AddArgument($Action)
    [void]$installPowerShell.AddArgument((Join-Path $script:Root 'WingetUserHelper.ps1'))
    [void]$installPowerShell.AddArgument($installLogQueue)
    [void]$installPowerShell.AddArgument($installFinishedQueue)
    $installAsyncResult = $installPowerShell.BeginInvoke()
    $installTimer = New-Object System.Windows.Threading.DispatcherTimer
    $installTimer.Interval = [TimeSpan]::FromMilliseconds(100)
    $installTimer.Add_Tick({
        $message = $null
        while ($installLogQueue.TryDequeue([ref]$message)) { Write-Log $message }
        $finished = $false
        if ($installFinishedQueue.TryDequeue([ref]$finished) -or $installAsyncResult.IsCompleted) {
            while ($installLogQueue.TryDequeue([ref]$message)) { Write-Log $message }
            $this.Stop()
            $installPowerShell.Dispose()
            $installRunspace.Dispose()
            foreach ($item in $appItems) {
                try {
                    $item.Installed = (& winget.exe list --id $item.Id --exact --accept-source-agreements 2>$null | Out-String) -match [regex]::Escape($item.Id)
                } catch { $item.Installed = $false }
                $item.Check.Content = if ($item.Installed) { "$($item.Name) (installed)" } else { $item.Name }
                $item.Check.IsChecked = $false
            }
            $InstallSelected.IsEnabled = $true
            $UninstallSelected.IsEnabled = $true
            Write-Log "Application $Action operation complete."
        }
    }.GetNewClosure())
    $installTimer.Start()
}

$InstallSelected.Add_Click({ Start-AppOperation 'install' })
$UninstallSelected.Add_Click({ Start-AppOperation 'uninstall' })

$RunDebloat.Add_Click({
    $selectedApps = @($removalCatalog | Where-Object { -not ($KeepTeams.IsChecked -and $_ -eq 'Microsoft.Teams') })
    $confirm = [System.Windows.Forms.MessageBox]::Show("Run debloat and remove $($selectedApps.Count) applications?`r`n`r`nMicrosoft Teams will be kept: $($KeepTeams.IsChecked)", 'Confirm debloat', 'YesNo', 'Warning')
    if ($confirm -ne 'Yes') { return }
    $RunDebloat.IsEnabled = $false
    $removalLogQueue = [System.Collections.Concurrent.ConcurrentQueue[string]]::new()
    $removalFinishedQueue = [System.Collections.Concurrent.ConcurrentQueue[bool]]::new()
    $debloatWorker = {
        param($Apps, $LogQueue, $FinishedQueue)
        foreach ($app in $Apps) {
            $LogQueue.Enqueue("uninstall $app...")
            try {
                & winget.exe uninstall --name $app --scope user --accept-source-agreements 2>&1 | ForEach-Object { $LogQueue.Enqueue([string]$_) }
                $LogQueue.Enqueue("$app finished with exit code $LASTEXITCODE.")
            } catch { $LogQueue.Enqueue("Could not uninstall ${app}: $($_.Exception.Message)") }
        }
        $FinishedQueue.Enqueue($true)
    }
    $debloatRunspace = [runspacefactory]::CreateRunspace()
    $debloatRunspace.Open()
    $debloatPowerShell = [powershell]::Create()
    $debloatPowerShell.Runspace = $debloatRunspace
    [void]$debloatPowerShell.AddScript($debloatWorker)
    [void]$debloatPowerShell.AddArgument($selectedApps)
    [void]$debloatPowerShell.AddArgument($removalLogQueue)
    [void]$debloatPowerShell.AddArgument($removalFinishedQueue)
    $debloatAsyncResult = $debloatPowerShell.BeginInvoke()
    $debloatTimer = New-Object System.Windows.Threading.DispatcherTimer
    $debloatTimer.Interval = [TimeSpan]::FromMilliseconds(100)
    $debloatTimer.Add_Tick({
        $message = $null
        while ($removalLogQueue.TryDequeue([ref]$message)) { Write-Log $message }
        $finished = $false
        if ($removalFinishedQueue.TryDequeue([ref]$finished) -or $debloatAsyncResult.IsCompleted) {
            while ($removalLogQueue.TryDequeue([ref]$message)) { Write-Log $message }
            $this.Stop()
            $debloatPowerShell.Dispose()
            $debloatRunspace.Dispose()
            $RunDebloat.IsEnabled = $true
            Write-Log 'Debloat complete.'
        }
    }.GetNewClosure())
    $debloatTimer.Start()
})

$ApplyCustomization.Add_Click({
    try {
        $advanced = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
        Set-ItemProperty -Path $advanced -Name HideFileExt -Value ([int](-not $ShowFileExtensions.IsChecked))
        Set-ItemProperty -Path $advanced -Name ShowTaskViewButton -Value ([int]$ShowTaskView.IsChecked)
        $recommended = 'HKCU:\SOFTWARE\Policies\Microsoft\Windows\Explorer'
        New-Item -Path $recommended -Force | Out-Null
        Set-ItemProperty -Path $recommended -Name HideRecommendedSection -Value ([int]$HideRecommended.IsChecked)
        $personalize = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize'
        Set-ItemProperty -Path $personalize -Name AppsUseLightTheme -Value ([int](-not $DarkMode.IsChecked))
        Set-ItemProperty -Path $personalize -Name SystemUsesLightTheme -Value ([int](-not $DarkMode.IsChecked))
        if ($DefenderPua.IsChecked) { Set-MpPreference -PUAProtection Enabled }
        Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
        Start-Process explorer.exe
        Write-Log 'Customization applied. Explorer restarted.'
    } catch { Write-Log "Customization failed: $($_.Exception.Message)" }
})

function Update-CleanupProfileState {
    if ($Global:ApplyingCleanupProfile) { return }
    $isDefault = $CleanupTemp.IsChecked -and $CleanupRecycle.IsChecked -and $CleanupCleanmgr.IsChecked -and $CleanupDns.IsChecked -and $CleanupDism.IsChecked
    $isServer = $CleanupTemp.IsChecked -and $CleanupRecycle.IsChecked -and $CleanupCleanmgr.IsChecked -and (-not $CleanupDns.IsChecked) -and (-not $CleanupDism.IsChecked)
    if ($isDefault) {
        $DefaultProfile.Background = '#007ACC'
        $ServerProfile.Background = '#2D2D30'
        $CustomProfile.Background = '#2D2D30'
    } elseif ($isServer) {
        $DefaultProfile.Background = '#2D2D30'
        $ServerProfile.Background = '#007ACC'
        $CustomProfile.Background = '#2D2D30'
    } else {
        $DefaultProfile.Background = '#2D2D30'
        $ServerProfile.Background = '#2D2D30'
        $CustomProfile.Background = '#007ACC'
        $CleanupStatus.Text = 'Custom cleanup profile selected.'
    }
}

function Set-CleanupProfile([string]$ProfileName) {
    $Global:ApplyingCleanupProfile = $true
    switch ($ProfileName) {
        'Default' {
            $CleanupTemp.IsChecked = $true
            $CleanupRecycle.IsChecked = $true
            $CleanupCleanmgr.IsChecked = $true
            $CleanupDns.IsChecked = $true
            $CleanupDism.IsChecked = $true
            $CleanupStatus.Text = 'Default cleanup profile selected.'
        }
        'Server' {
            $CleanupTemp.IsChecked = $true
            $CleanupRecycle.IsChecked = $true
            $CleanupCleanmgr.IsChecked = $true
            $CleanupDns.IsChecked = $false
            $CleanupDism.IsChecked = $false
            $CleanupStatus.Text = 'Server cleanup profile selected.'
        }
        'Custom' { $CleanupStatus.Text = 'Custom profile selected. Choose the tasks to run.' }
    }
    $Global:ApplyingCleanupProfile = $false
    Update-CleanupProfileState
    Write-Log "Cleanup profile: $ProfileName"
}

$DefaultProfile.Add_Click({ Set-CleanupProfile 'Default' })
$ServerProfile.Add_Click({ Set-CleanupProfile 'Server' })
$CustomProfile.Add_Click({ Set-CleanupProfile 'Custom' })
$profileCheckboxes = @($CleanupTemp, $CleanupRecycle, $CleanupCleanmgr, $CleanupDns, $CleanupDism)
$profileCheckboxes | ForEach-Object {
    $_.Add_Checked({ Update-CleanupProfileState }.GetNewClosure())
    $_.Add_Unchecked({ Update-CleanupProfileState }.GetNewClosure())
}

function Write-CleanupLog([string]$Message) {
    Write-Log $Message
}

function Refresh-CleanupUi {
    $frame = New-Object System.Windows.Threading.DispatcherFrame
    $window.Dispatcher.BeginInvoke([System.Windows.Threading.DispatcherPriority]::Render, [Action]{ $frame.Continue = $false }) | Out-Null
    [System.Windows.Threading.Dispatcher]::PushFrame($frame)
}

$StartCleanup.Add_Click({
    $selectedTasks = @{
        DoTemp = $CleanupTemp.IsChecked; DoRecycle = $CleanupRecycle.IsChecked
        DoCleanmgr = $CleanupCleanmgr.IsChecked; DoFlushDNS = $CleanupDns.IsChecked; DoDism = $CleanupDism.IsChecked
    }
    $total = @($selectedTasks.Values | Where-Object { $_ -eq $true }).Count
    if ($total -eq 0) { $CleanupStatus.Text = 'Select at least one cleanup task.'; return }

    $StartCleanup.IsEnabled = $false
    $Log.Clear()
    $CleanupStatus.Text = 'Cleaning...'
    $Global:LogQueue = [System.Collections.Concurrent.ConcurrentQueue[string]]::new()
    $Global:ProgressQueue = [System.Collections.Concurrent.ConcurrentQueue[hashtable]]::new()
    $Global:FinishedQueue = [System.Collections.Concurrent.ConcurrentQueue[bool]]::new()

    $worker = {
        param($CurrentDir, $RegFiles, $Tasks, $LogQueue, $ProgressQueue, $FinishedQueue)
        function Send-Log ($message) { if (-not [string]::IsNullOrWhiteSpace($message)) { $LogQueue.Enqueue($message) } }
        function Send-Progress ($value, $status) { $ProgressQueue.Enqueue(@{ Value = $value; Status = $status }) }
        function Invoke-SilentProcess ($fileName, $arguments) {
            $process = $null
            try {
                $info = New-Object System.Diagnostics.ProcessStartInfo -Property @{
                    FileName = $fileName; Arguments = $arguments; UseShellExecute = $false
                    RedirectStandardOutput = $true; RedirectStandardError = $true; CreateNoWindow = $true
                }
                $process = [System.Diagnostics.Process]::Start($info)
                while (-not $process.StandardOutput.EndOfStream) {
                    $line = $process.StandardOutput.ReadLine()
                    if ($line) { Send-Log $line.Trim() }
                }
                while (-not $process.StandardError.EndOfStream) {
                    $line = $process.StandardError.ReadLine()
                    if ($line) { Send-Log $line.Trim() }
                }
                $process.WaitForExit()
                Send-Log "$fileName finished with exit code $($process.ExitCode)."
            } catch { Send-Log "$fileName could not run: $($_.Exception.Message)" }
            finally { if ($process) { $process.Dispose() } }
        }
        $totalTasks = @($Tasks.Values | Where-Object { $_ -eq $true }).Count
        $completedTasks = 0
        foreach ($file in $RegFiles) {
            $filePath = Join-Path $CurrentDir $file
            if (Test-Path $filePath) { Invoke-SilentProcess 'reg.exe' "import `"$filePath`"" }
        }
        if ($Tasks.DoTemp) {
            Send-Progress 0 'Clearing temporary files...'; Send-Log '=== CLEARING TEMP FILES AND LOGS ==='
            @('C:\Windows\Temp\*','C:\Windows\Prefetch\*','C:\Windows\SoftwareDistribution\Download\*',"$([System.IO.Path]::GetTempPath())*",'C:\Intel','C:\PerfLogs') | ForEach-Object { if (Test-Path $_) { Send-Log "Deleting files in: $_"; Remove-Item $_ -Recurse -Force -ErrorAction SilentlyContinue } }
            $completedTasks++; Send-Progress ([Math]::Round(($completedTasks / $totalTasks) * 100) ) 'Temp files cleared.'
        }
        if ($Tasks.DoRecycle) {
            Send-Progress ([Math]::Round(($completedTasks / $totalTasks) * 100)) 'Emptying Recycle Bin...'; Send-Log '=== EMPTYING RECYCLE BIN ==='
            Clear-RecycleBin -Force -ErrorAction SilentlyContinue
            $completedTasks++; Send-Progress ([Math]::Round(($completedTasks / $totalTasks) * 100)) 'Recycle bin emptied.'
        }
        if ($Tasks.DoCleanmgr) {
            Send-Progress ([Math]::Round(($completedTasks / $totalTasks) * 100)) 'Running Disk Cleanup Utility...'; Send-Log '=== RUNNING CLEANMGR UTILITY ==='
            $previousInstallations = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Previous Installations'
            if (Test-Path $previousInstallations) { Set-ItemProperty $previousInstallations StateFlags0001 2 -Type DWord -ErrorAction SilentlyContinue; Set-ItemProperty $previousInstallations StateFlags0002 2 -Type DWord -ErrorAction SilentlyContinue }
            Invoke-SilentProcess 'cleanmgr.exe' $(if (Test-Path 'C:\Windows.old') { '/SAGERUN:1' } else { '/SAGERUN:2' })
            $completedTasks++; Send-Progress ([Math]::Round(($completedTasks / $totalTasks) * 100)) 'Disk cleanup complete.'
        }
        if ($Tasks.DoFlushDNS) {
            Send-Progress ([Math]::Round(($completedTasks / $totalTasks) * 100)) 'Flushing DNS Cache...'; Send-Log '=== FLUSHING DNS CACHE ==='
            Invoke-SilentProcess 'ipconfig.exe' '/flushdns'
            $completedTasks++; Send-Progress ([Math]::Round(($completedTasks / $totalTasks) * 100)) 'DNS Cache flushed.'
        }
        if ($Tasks.DoDism) {
            Send-Progress ([Math]::Round(($completedTasks / $totalTasks) * 100)) 'Optimizing DISM Component Store...'; Send-Log '=== RUNNING DISM COMPONENT STORE CLEANUP ==='
            Invoke-SilentProcess 'Dism.exe' '/online /Cleanup-Image /StartComponentCleanup /ResetBase /NoRestart /English'
            $completedTasks++; Send-Progress ([Math]::Round(($completedTasks / $totalTasks) * 100)) 'DISM cleanup complete.'
        }
        Send-Progress 100 'Optimization Complete!'; $FinishedQueue.Enqueue($true)
    }
    $Global:Runspace = [runspacefactory]::CreateRunspace(); $Global:Runspace.Open()
    $Global:PowerShell = [powershell]::Create(); $Global:PowerShell.Runspace = $Global:Runspace
    [void]$Global:PowerShell.AddScript($worker)
    @($script:Root, @('SystemCleanUp\DiskCleanupSettings.reg', 'SystemCleanUp\DiskCleanupSettings2.reg'), $selectedTasks, $Global:LogQueue, $Global:ProgressQueue, $Global:FinishedQueue) | ForEach-Object { [void]$Global:PowerShell.AddArgument($_) }
    $Global:AsyncResult = $Global:PowerShell.BeginInvoke()
    $timer = New-Object System.Windows.Threading.DispatcherTimer
    $timer.Interval = [TimeSpan]::FromMilliseconds(50)
    $timer.Add_Tick({
        $message = $null; while ($Global:LogQueue.TryDequeue([ref]$message)) { Write-CleanupLog $message }
        $progress = $null; while ($Global:ProgressQueue.TryDequeue([ref]$progress)) { $CleanupProgress.Value = $progress.Value; $CleanupProgressPercent.Text = "$($progress.Value)%"; $CleanupStatus.Text = $progress.Status }
        $finished = $false
        if ($Global:FinishedQueue.TryDequeue([ref]$finished) -or $Global:AsyncResult.IsCompleted) {
            while ($Global:LogQueue.TryDequeue([ref]$message)) { Write-CleanupLog $message }
            while ($Global:ProgressQueue.TryDequeue([ref]$progress)) { $CleanupProgress.Value = $progress.Value; $CleanupProgressPercent.Text = "$($progress.Value)%"; $CleanupStatus.Text = $progress.Status }
            $this.Stop(); $Global:PowerShell.Dispose(); $Global:Runspace.Dispose()
            $CleanupStatus.Text = 'Cleanup complete.'; Write-CleanupLog "=== CLEANUP COMPLETE ($total/$total tasks) ==="; $StartCleanup.IsEnabled = $true
        }
    }.GetNewClosure())
    $timer.Start()
})

Write-Log 'Ready. Choose a page to begin.'
$window.Add_Loaded({
    try {
        $hwnd = (New-Object System.Windows.Interop.WindowInteropHelper($window)).Handle
        $darkTealColor = 0x00382D12
        [Win32.DwmApi]::DwmSetWindowAttribute($hwnd, 35, [ref]$darkTealColor, [System.Runtime.InteropServices.Marshal]::SizeOf([type][int])) | Out-Null
    } catch {}
}.GetNewClosure())
$HeaderVersion.Text = "v$script:AppVersion"
$logoPath = Join-Path $script:Root 'SystemCleanUp\LogoRight.jpg'
if (Test-Path -LiteralPath $logoPath) {
    $bitmap = New-Object System.Windows.Media.Imaging.BitmapImage
    $bitmap.BeginInit()
    $bitmap.UriSource = New-Object System.Uri($logoPath, [System.UriKind]::Absolute)
    $bitmap.CacheOption = [System.Windows.Media.Imaging.BitmapCacheOption]::OnLoad
    $bitmap.EndInit()
    $HeaderLogo.Source = $bitmap
}
$MainTabs.SelectedIndex = 0
$startupTimer = New-Object System.Windows.Threading.DispatcherTimer
$startupTimer.Interval = [TimeSpan]::FromMilliseconds(100)
$startupTimer.Add_Tick({
    $this.Stop()
    Initialize-AppItems
    Update-InfoPage
}.GetNewClosure())
$startupTimer.Start()
$window.ShowDialog() | Out-Null
