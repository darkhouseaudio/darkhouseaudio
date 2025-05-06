param (
    [string]$WebhookUrl = "http://localhost:8080/webhook",
    [string]$Email = "",
    [string]$OrderId = ""
)

# Script to test the webhook functionality by sending a test payment event
# Usage: .\test-webhook.ps1 [-WebhookUrl http://localhost:8080/webhook] [-Email customer@example.com] [-OrderId ORDER123]

Add-Type -AssemblyName System.Web

# Function to prompt for input if not provided
function Get-UserInput($prompt, $default) {
    $result = Read-Host -Prompt "$prompt [$default]"
    if ([string]::IsNullOrWhiteSpace($result)) { $result = $default }
    return $result
}

# Get webhook URL if not provided
if ([string]::IsNullOrWhiteSpace($WebhookUrl)) {
    $WebhookUrl = Get-UserInput "Enter webhook URL" "http://localhost:8080/webhook"
}

# Show menu for selecting payment processor type
Write-Host "`nSelect payment processor:" -ForegroundColor Cyan
Write-Host "1. PayPal"
Write-Host "2. Stripe"
Write-Host "3. Gumroad"
$processorChoice = Read-Host "Enter choice (1-3)"

# Get customer email if not provided
if ([string]::IsNullOrWhiteSpace($Email)) {
    $Email = Get-UserInput "Enter customer email" "test@example.com"
}

# Get order ID if not provided
if ([string]::IsNullOrWhiteSpace($OrderId)) {
    $OrderId = Get-UserInput "Enter order ID" ("ORDER-" + (Get-Random -Minimum 10000 -Maximum 99999))
}

# Create webhook payload based on selected processor
$payload = $null

switch ($processorChoice) {
    "1" {
        # PayPal format
        $payload = @{
            id = "WH-" + (New-Guid).ToString().Substring(0, 8)
            event_type = "PAYMENT.SALE.COMPLETED"
            resource = @{
                id = $OrderId
                payer = @{
                    email_address = $Email
                }
            }
        } | ConvertTo-Json -Depth 10
        Write-Host "`nUsing PayPal format" -ForegroundColor Green
    }
    "2" {
        # Stripe format
        $payload = @{
            id = "evt_" + (New-Guid).ToString().Substring(0, 8)
            type = "checkout.session.completed"
            data = @{
                object = @{
                    id = "cs_" + (New-Guid).ToString().Substring(0, 8)
                    customer_email = $Email
                    payment_intent = $OrderId
                }
            }
        } | ConvertTo-Json -Depth 10
        Write-Host "`nUsing Stripe format" -ForegroundColor Green
    }
    "3" {
        # Gumroad format
        $payload = @{
            email = $Email
            order_id = $OrderId
            price = "USD 29.00"
            product_name = "BleedShift 2"
        } | ConvertTo-Json
        Write-Host "`nUsing Gumroad format" -ForegroundColor Green
    }
    default {
        # Default to Gumroad (simplest format)
        $payload = @{
            email = $Email
            order_id = $OrderId
            price = "USD 29.00"
            product_name = "BleedShift 2"
        } | ConvertTo-Json
        Write-Host "`nUsing default format (Gumroad)" -ForegroundColor Yellow
    }
}

# Show the payload that will be sent
Write-Host "`nSending webhook payload:" -ForegroundColor Cyan
Write-Host $payload

# Confirm before sending
$confirm = Read-Host "`nSend this webhook? (y/n)"
if ($confirm -ne "y") {
    Write-Host "Webhook sending cancelled." -ForegroundColor Yellow
    exit
}

try {
    # Send the webhook
    $headers = @{
        "Content-Type" = "application/json"
    }
    
    Write-Host "`nSending webhook to $WebhookUrl..." -ForegroundColor Cyan
    
    $response = Invoke-RestMethod -Uri $WebhookUrl -Method Post -Body $payload -Headers $headers
    
    Write-Host "Webhook sent successfully!" -ForegroundColor Green
    Write-Host "Response: $response"
} catch {
    Write-Host "Error sending webhook: $_" -ForegroundColor Red
} 