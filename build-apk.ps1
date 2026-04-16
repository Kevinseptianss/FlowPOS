# FlowPOS Build Script
# This script builds the production APK and opens the output folder

Write-Host "----------------------------------------------------" -ForegroundColor Cyan
Write-Host "Building Production APK..." -ForegroundColor Cyan
Write-Host "----------------------------------------------------" -ForegroundColor Cyan

# Run flutter build
flutter build apk --flavor production

if ($LASTEXITCODE -eq 0) {
    Write-Host "`nBuild Successful!" -ForegroundColor Green
    $outputPath = "build\app\outputs\flutter-apk\"
    
    Write-Host "Opening output folder: $outputPath" -ForegroundColor Yellow
    explorer $outputPath
} else {
    Write-Host "`nBuild Failed with exit code $LASTEXITCODE" -ForegroundColor Red
    exit $LASTEXITCODE
}
