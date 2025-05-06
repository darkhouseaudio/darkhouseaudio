@echo off
echo Pushing all updates to GitHub...
git add .
git commit -m "Automatic update %date% %time%"
git push
echo Done!
pause 