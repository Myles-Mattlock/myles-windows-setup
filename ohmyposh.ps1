if (-not (Get-Command pwsh)) {
    Write-Host "Powershell 7 not found installing..."
    Install-WinUtilWinget
    winget install Microsoft.PowerShell --source winget --silentwt new-tab pwsh -NoExit -Command "irm https://github.com/Myles-Mattlock/ohmyposh/raw/main/setup.ps1 | iex"