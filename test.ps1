# 1. Define paths (Update the source path to your file's actual location)
$SourceCursor = "Text-Select-Myles.cur"
$DestinationFolder = "$env:SystemRoot\Cursors"
$DestinationPath = Join-Path $DestinationFolder "Text-Select-Myles.cur"

# 2. Copy the custom file with the new name
if (Test-Path $SourceCursor) {
    Copy-Item -Path $SourceCursor -Destination $DestinationPath -Force
    Write-Host "Copied custom cursor to $DestinationPath" -ForegroundColor Green
} else {
    Write-Error "Source file not found at $SourceCursor."
    exit
}

# 3. Define the string for the new Scheme
# This maps every cursor type to its default file, EXCEPT the text select (IBeam)
$SchemeName = "Windows Default Myles"
$SchemeData = "%SystemRoot%\cursors\aero_arrow.cur,%SystemRoot%\cursors\aero_helpsel.cur,%SystemRoot%\cursors\aero_working.ani,%SystemRoot%\cursors\aero_busy.ani,$DestinationPath,%SystemRoot%\cursors\aero_unavail.cur,%SystemRoot%\cursors\aero_ns.cur,%SystemRoot%\cursors\aero_ew.cur,%SystemRoot%\cursors\aero_nwse.cur,%SystemRoot%\cursors\aero_nesw.cur,%SystemRoot%\cursors\aero_move.cur,%SystemRoot%\cursors\aero_up.cur,%SystemRoot%\cursors\aero_link.cur,%SystemRoot%\cursors\aero_pin.cur,%SystemRoot%\cursors\aero_person.cur"

# 4. Add the new scheme to the list of available schemes
$SchemesRegistryPath = "HKCU:\Control Panel\Cursors\Schemes"
Set-ItemProperty -Path $SchemesRegistryPath -Name $SchemeName -Value $SchemeData

# 5. Apply the scheme values to the active cursor settings
$ActiveRegistryPath = "HKCU:\Control Panel\Cursors"
Set-ItemProperty -Path $ActiveRegistryPath -Name "(Default)" -Value $SchemeName
Set-ItemProperty -Path $ActiveRegistryPath -Name "Scheme Name" -Value $SchemeName

# Update the specific pointers in the active configuration
Set-ItemProperty -Path $ActiveRegistryPath -Name "Arrow" -Value "$DestinationFolder\aero_arrow.cur"
Set-ItemProperty -Path $ActiveRegistryPath -Name "Help" -Value "$DestinationFolder\aero_helpsel.cur"
Set-ItemProperty -Path $ActiveRegistryPath -Name "AppStarting" -Value "$DestinationFolder\aero_working.ani"
Set-ItemProperty -Path $ActiveRegistryPath -Name "Wait" -Value "$DestinationFolder\aero_busy.ani"
Set-ItemProperty -Path $ActiveRegistryPath -Name "IBeam" -Value $DestinationPath
Set-ItemProperty -Path $ActiveRegistryPath -Name "No" -Value "$DestinationFolder\aero_unavail.cur"
Set-ItemProperty -Path $ActiveRegistryPath -Name "SizeNS" -Value "$DestinationFolder\aero_ns.cur"
Set-ItemProperty -Path $ActiveRegistryPath -Name "SizeWE" -Value "$DestinationFolder\aero_ew.cur"
Set-ItemProperty -Path $ActiveRegistryPath -Name "SizeNWSE" -Value "$DestinationFolder\aero_nwse.cur"
Set-ItemProperty -Path $ActiveRegistryPath -Name "SizeNESW" -Value "$DestinationFolder\aero_nesw.cur"
Set-ItemProperty -Path $ActiveRegistryPath -Name "SizeAll" -Value "$DestinationFolder\aero_move.cur"
Set-ItemProperty -Path $ActiveRegistryPath -Name "UpArrow" -Value "$DestinationFolder\aero_up.cur"
Set-ItemProperty -Path $ActiveRegistryPath -Name "Hand" -Value "$DestinationFolder\aero_link.cur"
Set-ItemProperty -Path $ActiveRegistryPath -Name "Pin" -Value "$DestinationFolder\aero_pin.cur"
Set-ItemProperty -Path $ActiveRegistryPath -Name "Person" -Value "$DestinationFolder\aero_person.cur"

# 6. Broadcast the change to Windows to refresh the cursors instantly
$CSharpSig = @'
[DllImport("user32.dll", EntryPoint = "SystemParametersInfo")]
public static extern bool SystemParametersInfo(uint uiAction, uint uiParam, string pvParam, uint fWinIni);
'@

$User32 = Add-Type -MemberDefinition $CSharpSig -Name "User32" -Namespace "Win32" -PassThru
$User32::SystemParametersInfo(0x0057, 0, $null, 3)

Write-Host "Scheme '$SchemeName' created and applied successfully!" -ForegroundColor Green