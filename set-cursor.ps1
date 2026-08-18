# 1. Define paths (Replace the source path with where your file actually lives)
$SourceCursor = "Text-Select-Myles.cur"
$DestinationFolder = "$env:SystemRoot\Cursors"
$DestinationPath = Join-Path $DestinationFolder "Text-Select-Myles.cur"

# 2. Copy the file to the Windows Cursors folder
if (Test-Path $SourceCursor) {
    Copy-Item -Path $SourceCursor -Destination $DestinationPath -Force
    Write-Host "Successfully copied cursor to $DestinationPath" -ForegroundColor Green
} else {
    Write-Error "Source file not found at $SourceCursor. Please check the path."
    exit
}

# 3. Update the Registry for the Text Select cursor (IBeam)
# 'IBeam' is the internal Windows identifier for the text selection cursor
$RegistryPath = "HKCU:\Control Panel\Cursors"
Set-ItemProperty -Path $RegistryPath -Name "IBeam" -Value $DestinationPath

# 4. Broadcast the change to the system so it applies instantly without a reboot
$CSharpSig = @'
[DllImport("user32.dll", EntryPoint = "SystemParametersInfo")]
public static extern bool SystemParametersInfo(uint uiAction, uint uiParam, string pvParam, uint fWinIni);
'@

$User32 = Add-Type -MemberDefinition $CSharpSig -Name "User32" -Namespace "Win32" -PassThru
# SPI_SETCURSORS (0x0057) forces Windows to reload cursors from the registry
$User32::SystemParametersInfo(0x0057, 0, $null, 3)

Write-Host "Text select cursor updated successfully!" -ForegroundColor Green