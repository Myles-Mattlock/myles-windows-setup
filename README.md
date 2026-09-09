# MylesMattlockWinTool

PowerShell WPF tool for managing a Windows workstation from separate pages:

- **Install / Remove Apps**: install common applications with `winget` and remove selected Windows apps.
- **Customization**: apply Explorer, Start, theme, and Defender preferences.
- **Cleanup**: run the cleanup tasks directly inside the tool, with the same task selection and terminal-style logging as the original cleanup interface.

## Run

Open PowerShell as needed and run:

```powershell
Set-ExecutionPolicy -Scope Process Bypass
.\MylesMattlockWinTool.ps1
```

To launch it without leaving a PowerShell window visible, run:

```powershell
Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PWD\MylesMattlockWinTool.ps1`"" -WindowStyle Hidden
```

The tool self-elevates to administrator. `CleanUp.ps1` remains in the repository as the original standalone cleanup implementation, but the main tool does not launch it.