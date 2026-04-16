# FlowPOS Database Reset Script
# WARNING: This will delete ALL collections in your Firestore database!

Write-Host "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!" -ForegroundColor Red
Write-Host "CRITICAL WARNING: DATABASE RESET" -ForegroundColor Red
Write-Host "This script will delete ALL collections from: flowpos-4531e" -ForegroundColor Red
Write-Host "This action is PERMANENT and CANNOT be undone." -ForegroundColor Red
Write-Host "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!" -ForegroundColor Red

$confirm = Read-Host "`nType 'DELETE ALL' to confirm database wipe"

if ($confirm -eq "DELETE ALL") {
    Write-Host "`nStarting database wipe..." -ForegroundColor Yellow
    firebase firestore:delete --all-collections --project flowpos-4531e --force
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "`nDatabase has been successfully cleared." -ForegroundColor Green
    } else {
        Write-Host "`nDatabase reset failed. Please check if you are logged in to Firebase (run 'firebase login')." -ForegroundColor Red
    }
} else {
    Write-Host "`nOperation cancelled. No changes were made." -ForegroundColor Cyan
}
