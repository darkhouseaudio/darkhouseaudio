@echo off
echo Pushing all updates to GitHub...

:: First, add all standard files
git add .

:: Force add the webhook and workflows directories
git add webhook-handler/ -f
git add .github/workflows/ -f  

:: Commit all changes
git commit -m "Automatic update %date% %time%"

:: Push to GitHub
git push

echo Done!