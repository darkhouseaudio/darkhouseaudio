# Dark House Audio Webhook Handler

This service automatically processes payment notifications from your payment processor and updates the purchases database.

## How It Works

1. When a customer makes a purchase, your payment processor sends a webhook notification to this service
2. The service extracts the customer's email and order ID from the notification
3. It triggers a GitHub Actions workflow that adds the purchase to the `purchases.json` file
4. The workflow automatically commits and pushes the changes to your repository
5. Your website verifies purchases using the updated `purchases.json` file

## Setup Instructions

### 1. GitHub Setup

1. Go to your GitHub account settings → Developer settings → Personal access tokens
2. Generate a new token with the `repo` scope
3. Copy the token for later use
4. In your repository, go to Settings → Secrets and variables → Actions
5. Add a new repository secret called `GITHUB_TOKEN` with your token

### 2. Environment Configuration

Create a `.env` file with the following variables:

```
# GitHub Repository Details
GITHUB_REPO_OWNER=your-github-username
GITHUB_REPO_NAME=darkhouseaudio
GITHUB_TOKEN=your-github-personal-access-token

# Server Configuration
PORT=3000

# Payment Processor (uncomment and configure for your payment processor)
# For PayPal
# WEBHOOK_SECRET=your-paypal-webhook-secret

# For Stripe
# WEBHOOK_SECRET=your-stripe-webhook-secret

# For Gumroad
# WEBHOOK_SECRET=your-gumroad-webhook-secret
```

### 3. Deployment

#### Local Testing

```
npm install
npm run dev
```

#### Production Deployment Options

**Render.com**
1. Push this code to your repository
2. Create a new Web Service on Render.com
3. Connect to your GitHub repository
4. Set the build command to `npm install`
5. Set the start command to `npm start`
6. Add the environment variables from your `.env` file

**Vercel**
1. Push this code to your repository
2. Create a new project on Vercel
3. Connect to your GitHub repository
4. Add the environment variables from your `.env` file

### 4. Configure Your Payment Processor

#### PayPal

1. Go to your PayPal Developer Dashboard → Webhooks
2. Add a new webhook with the URL: `https://your-webhook-url.com/webhook/payment`
3. Subscribe to the "Payment sale completed" event
4. Copy the webhook secret and add it to your `.env` file

#### Stripe

1. Go to your Stripe Dashboard → Developers → Webhooks
2. Add a new endpoint with the URL: `https://your-webhook-url.com/webhook/payment`
3. Subscribe to the "checkout.session.completed" event
4. Copy the signing secret and add it to your `.env` file

#### Gumroad

1. Go to your Gumroad Dashboard → Settings → Advanced → Ping
2. Add the URL: `https://your-webhook-url.com/webhook/payment`
3. Save your changes

## Customization

Modify the `extractPaymentDetails` function in `index.js` to match your payment processor's webhook format. 