param (
    [string]$CommitMessage = "Update purchases database"
)

# Check if we're in the right directory
if (-not (Test-Path "purchases.json")) {
    Write-Error "purchases.json not found in current directory."
    exit 1
}

# Run Git commands
Write-Host "Adding purchases.json to Git staging..." -ForegroundColor Cyan
git add purchases.json

Write-Host "Committing changes with message: $CommitMessage" -ForegroundColor Cyan
git commit -m $CommitMessage

Write-Host "Pushing changes to remote repository..." -ForegroundColor Cyan
git push

Write-Host "Done!" -ForegroundColor Green
Write-Host "Press any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") 