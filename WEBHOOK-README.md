# Dark House Audio Automated Purchase System

This system enables automatic processing of purchases through webhook notifications from payment processors like PayPal, Stripe, or Gumroad. It eliminates the need for manual updates to the purchase database.

## How It Works

1. When a customer makes a purchase, your payment processor sends a webhook notification
2. The webhook server receives the notification and extracts the customer's email and order ID
3. The system automatically updates `purchases.json` and commits changes to GitHub
4. Your website verifies purchases using the updated database

## Files Included

- `payment-webhook-receiver.ps1` - The main webhook server
- `auto-update-purchases.ps1` - Script to update purchases.json and commit changes
- `start-webhook-server.bat` - Easy-to-use batch file to start the webhook server
- `test-webhook.ps1` - Test script to simulate payment webhooks
- `push-updates.bat` - Updated script to push all changes to GitHub

## Setup Instructions

### 1. Local Setup

1. Make sure all files are in your main repository directory
2. Run `start-webhook-server.bat` to start the webhook server
3. The server will run at `http://localhost:8080/webhook`

### 2. Configure Your Payment Processor

#### PayPal

1. Go to PayPal Developer Dashboard → Webhooks
2. Add a new webhook with the URL: `https://your-public-url/webhook`
   (You'll need to make your localhost accessible from the internet - see options below)
3. Subscribe to the "Payment sale completed" event

#### Stripe

1. Go to Stripe Dashboard → Developers → Webhooks
2. Add a new endpoint with the URL: `https://your-public-url/webhook`
3. Subscribe to the "checkout.session.completed" event

#### Gumroad

1. Go to Gumroad Dashboard → Settings → Advanced → Ping
2. Add the URL: `https://your-public-url/webhook`

### 3. Make Your Local Server Accessible

You need to make your local webhook server accessible from the internet. Options include:

#### Option 1: Port Forwarding (if you have control over your router)
1. Configure your router to forward port 8080 to your local machine
2. Use a service like No-IP or DynDNS to get a domain name pointing to your public IP

#### Option 2: Ngrok (easiest)
1. Download [ngrok](https://ngrok.com/) and sign up for a free account
2. Start your webhook server with `start-webhook-server.bat`
3. Run ngrok: `ngrok http 8080`
4. Use the HTTPS URL provided by ngrok (e.g., `https://abc123.ngrok.io/webhook`)

## Testing the System

1. Start the webhook server using `start-webhook-server.bat`
2. In a separate PowerShell window, run `.\test-webhook.ps1`
3. Follow the prompts to select a payment processor and enter test data
4. The webhook will be sent to your local server
5. Check that `purchases.json` is updated and committed to GitHub

## Troubleshooting

- **Server won't start**: Make sure you're running as Administrator
- **Webhook not received**: Check your firewall settings
- **Git commits failing**: Make sure your Git credentials are properly configured
- **Changes not showing on website**: Verify GitHub Pages has deployed the updates

## Support

If you need assistance, contact darkhouseaudio@gmail.com with your specific issue. 