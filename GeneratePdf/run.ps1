param($Request, $TriggerMetadata)

Write-Host "🚀 FusionExport Function Triggered"

$root = $env:HOME
$batPath = Join-Path $root "site\wwwroot\run.bat"

if (!(Test-Path $batPath)) {
    Write-Host "❌ run.bat not found at $batPath"
    return @{
        statusCode = 500
        body = "run.bat not found"
    }
}

Write-Host "▶ Starting FusionExport batch..."
Start-Process -FilePath "cmd.exe" -ArgumentList "/c `"$batPath`"" -Wait -NoNewWindow

# Look for latest generated PDF in output folder
$outputDir = Join-Path $root "site\wwwroot\output"
if (Test-Path $outputDir) {
    $latest = Get-ChildItem $outputDir -Filter *.pdf | Sort-Object LastWriteTime -Descending | Select-Object -First 1
    if ($latest) {
        $bytes = [System.IO.File]::ReadAllBytes($latest.FullName)
        return @{
            statusCode = 200
            headers = @{ "Content-Type" = "application/pdf" }
            body = [Convert]::ToBase64String($bytes)
            isBase64Encoded = $true
        }
    }
}

return @{
    statusCode = 500
    body = "No PDF found after export."
}
