@echo off
echo Starting Dark House Audio Webhook Server...
echo You can send webhooks to http://localhost:8080/webhook
echo.
echo Press Ctrl+C to stop the server
powershell.exe -ExecutionPolicy Bypass -File "payment-webhook-receiver.ps1"
pause 