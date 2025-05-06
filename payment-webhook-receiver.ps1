# Payment Webhook Receiver
# This script starts a simple HTTP server to receive webhook notifications
# and automatically updates purchases.json when payments are received.

param (
    [int]$Port = 8080,
    [string]$WebhookPath = "webhook",
    [string]$WebhookSecret = ""  # Optional secret for validation
)

# Import required modules
Add-Type -AssemblyName System.Web
Add-Type -AssemblyName System.Net.Http

# Configuration
$baseUrl = "http://localhost:$Port/"
$updateScript = ".\auto-update-purchases.ps1"

# Create HTTP listener
$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add($baseUrl)

function Write-ColorOutput($ForegroundColor) {
    $fc = $host.UI.RawUI.ForegroundColor
    $host.UI.RawUI.ForegroundColor = $ForegroundColor
    if ($args) {
        Write-Output $args
    } else {
        $input | Write-Output
    }
    $host.UI.RawUI.ForegroundColor = $fc
}

# Function to extract payment data from different payment processors
function Extract-PaymentData($requestBody) {
    try {
        $json = $requestBody | ConvertFrom-Json
        
        # PayPal format
        if ($json.resource -and $json.resource.id -and $json.resource.payer.email_address) {
            return @{
                Email = $json.resource.payer.email_address
                OrderId = $json.resource.id
                Source = "PayPal"
            }
        }
        
        # Stripe format
        if ($json.data -and $json.data.object -and $json.data.object.customer_email) {
            return @{
                Email = $json.data.object.customer_email
                OrderId = $json.data.object.payment_intent
                Source = "Stripe"
            }
        }
        
        # Gumroad format
        if ($json.email -and $json.order_id) {
            return @{
                Email = $json.email
                OrderId = $json.order_id
                Source = "Gumroad"
            }
        }
        
        # If we got here, we couldn't identify the format
        Write-ColorOutput Yellow "Unknown webhook format: $requestBody"
        return $null
        
    } catch {
        Write-ColorOutput Red "Error extracting payment data: $_"
        return $null
    }
}

# Function to process webhook requests
function Process-Webhook($context) {
    $request = $context.Request
    $response = $context.Response
    
    # Read request body
    $reader = New-Object System.IO.StreamReader($request.InputStream, $request.ContentEncoding)
    $requestBody = $reader.ReadToEnd()
    
    Write-ColorOutput Cyan "Webhook received: $requestBody"
    
    # Extract payment data
    $paymentData = Extract-PaymentData $requestBody
    
    if ($paymentData) {
        Write-ColorOutput Green "Payment data extracted: $($paymentData.Email) / $($paymentData.OrderId) from $($paymentData.Source)"
        
        # Process payment by calling the auto-update-purchases.ps1 script
        $scriptParams = @{
            Email = $paymentData.Email
            OrderId = $paymentData.OrderId
        }
        
        try {
            # Start the update script as a separate process
            Start-Process powershell -ArgumentList "-File `"$updateScript`" -Email `"$($paymentData.Email)`" -OrderId `"$($paymentData.OrderId)`"" -NoNewWindow
            
            # Send success response
            $responseText = "Webhook processed successfully"
            $buffer = [System.Text.Encoding]::UTF8.GetBytes($responseText)
            $response.ContentLength64 = $buffer.Length
            $response.ContentType = "text/plain"
            $response.StatusCode = 200
            $response.OutputStream.Write($buffer, 0, $buffer.Length)
        } catch {
            # Send error response
            $errorMessage = "Error processing webhook: $_"
            Write-ColorOutput Red $errorMessage
            $buffer = [System.Text.Encoding]::UTF8.GetBytes($errorMessage)
            $response.ContentLength64 = $buffer.Length
            $response.ContentType = "text/plain"
            $response.StatusCode = 500
            $response.OutputStream.Write($buffer, 0, $buffer.Length)
        }
    } else {
        # Send bad request response
        $errorMessage = "Could not extract payment data"
        $buffer = [System.Text.Encoding]::UTF8.GetBytes($errorMessage)
        $response.ContentLength64 = $buffer.Length
        $response.ContentType = "text/plain"
        $response.StatusCode = 400
        $response.OutputStream.Write($buffer, 0, $buffer.Length)
    }
    
    $response.Close()
}

try {
    # Start the listener
    $listener.Start()
    Write-ColorOutput Green "Webhook server started at $baseUrl"
    Write-ColorOutput Yellow "Send webhooks to ${baseUrl}${WebhookPath}"
    Write-ColorOutput Yellow "Press Ctrl+C to stop the server"
    
    # Main loop
    while ($true) {
        $context = $listener.GetContext()
        $request = $context.Request
        
        # Log request
        Write-Host "[$([DateTime]::Now)] $($request.HttpMethod) $($request.Url.PathAndQuery) from $($request.RemoteEndPoint.Address)" -ForegroundColor Cyan
        
        # Check if this is a webhook request
        if ($request.HttpMethod -eq "POST" -and $request.Url.PathAndQuery -match "/$WebhookPath") {
            Process-Webhook $context
        } else {
            # Handle non-webhook requests (show a simple message)
            $response = $context.Response
            $responseText = "Dark House Audio Webhook Server Running"
            $buffer = [System.Text.Encoding]::UTF8.GetBytes($responseText)
            $response.ContentLength64 = $buffer.Length
            $response.ContentType = "text/plain"
            $response.StatusCode = 200
            $response.OutputStream.Write($buffer, 0, $buffer.Length)
            $response.Close()
        }
    }
} finally {
    # Stop the listener
    $listener.Stop()
    Write-ColorOutput Yellow "Webhook server stopped"
} 