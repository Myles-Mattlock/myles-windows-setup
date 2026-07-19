# Optimized Recall Check using Capability deployment
$recallCapability = Get-WindowsCapability -Online -Name "Windows.Client.AI.Recall*" -ErrorAction SilentlyContinue
if ($recallCapability -and $recallCapability.State -eq "Installed") {
    Write-Host "Disabling Recall..." -ForegroundColor Yellow
    DISM /Online /Disable-Feature /FeatureName=Recall /NoRestart /Quiet
} else {
    Write-Host "Recall is already disabled or not present on this build." -ForegroundColor Green
}