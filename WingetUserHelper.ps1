param(
    [Parameter(Mandatory = $true)][ValidateSet('install', 'uninstall')][string]$Action,
    [Parameter(Mandatory = $true)][string]$PackageId,
    [Parameter(Mandatory = $true)][string]$OutputPath,
    [Parameter(Mandatory = $true)][string]$ResultPath
)

try {
    Set-Content -LiteralPath $OutputPath -Value '' -Encoding UTF8
    if ($Action -eq 'install') {
        & winget.exe install --id $PackageId --exact --scope user --accept-source-agreements --accept-package-agreements 2>&1 | ForEach-Object {
            Add-Content -LiteralPath $OutputPath -Value ([string]$_) -Encoding UTF8
        }
    } else {
        & winget.exe uninstall --id $PackageId --exact --scope user --accept-source-agreements 2>&1 | ForEach-Object {
            Add-Content -LiteralPath $OutputPath -Value ([string]$_) -Encoding UTF8
        }
    }
    Set-Content -LiteralPath $ResultPath -Value ([string]$LASTEXITCODE) -Encoding ASCII
} catch {
    Add-Content -LiteralPath $OutputPath -Value $_.Exception.Message -Encoding UTF8
    Set-Content -LiteralPath $ResultPath -Value '1' -Encoding ASCII
}
