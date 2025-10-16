param($Request, $TriggerMetadata)

Write-Host "🚀 FusionExport Azure Function triggered."

$functionDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$rootDir = Join-Path $functionDir ".."

$batchFile = Join-Path $rootDir "run.bat"

if (!(Test-Path $batchFile)) {
    Write-Host "❌ run.bat not found"
    return @{
        statusCode = 500
        body = "run.bat not found"
    }
}

Write-Host "▶ Running FusionExport batch..."
$process = Start-Process -FilePath "cmd.exe" -ArgumentList "/c `"$batchFile`"" -WorkingDirectory $rootDir -NoNewWindow -Wait -PassThru

Write-Host "✅ Batch completed with exit code: $($process.ExitCode)"

$outputDir = Join-Path $rootDir "output"
if (Test-Path $outputDir) {
    $latestPdf = Get-ChildItem $outputDir -Filter *.pdf | Sort-Object LastWriteTime -Descending | Select-Object -First 1
    if ($latestPdf) {
        Write-Host "📄 Found PDF: $($latestPdf.Name)"
        $pdfBytes = [System.IO.File]::ReadAllBytes($latestPdf.FullName)
        return @{
            statusCode = 200
            headers = @{ "Content-Type" = "application/pdf" }
            body = [Convert]::ToBase64String($pdfBytes)
            isBase64Encoded = $true
        }
    }
}

return @{
    statusCode = 500
    body = "No PDF generated."
}
