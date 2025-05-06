require('dotenv').config();
const express = require('express');
const axios = require('axios');
const crypto = require('crypto');
const bodyParser = require('body-parser');

const app = express();
app.use(bodyParser.json());

// GitHub repository details
const GITHUB_REPO_OWNER = process.env.GITHUB_REPO_OWNER || 'your-github-username';
const GITHUB_REPO_NAME = process.env.GITHUB_REPO_NAME || 'darkhouseaudio';
const GITHUB_TOKEN = process.env.GITHUB_TOKEN; // Personal access token with repo scope

// Payment processor webhook secret for validation
const WEBHOOK_SECRET = process.env.WEBHOOK_SECRET;

// Verify webhook signature (example for PayPal - adjust for your payment processor)
function verifyWebhookSignature(req) {
  // This is an example for PayPal - modify according to your payment processor's requirements
  if (!WEBHOOK_SECRET) return true; // Skip verification in development
  
  const signature = req.headers['paypal-transmission-sig'];
  const transmissionId = req.headers['paypal-transmission-id'];
  const timestamp = req.headers['paypal-transmission-time'];
  
  // Compute the expected signature (this is PayPal-specific)
  const payload = transmissionId + '|' + timestamp + '|' + JSON.stringify(req.body);
  const expectedSignature = crypto
    .createHmac('sha256', WEBHOOK_SECRET)
    .update(payload)
    .digest('base64');
  
  return signature === expectedSignature;
}

// Extract payment details from webhook payload (adjust for your payment processor)
function extractPaymentDetails(payload) {
  // This is an example - modify based on your payment processor's webhook format
  try {
    // For PayPal
    if (payload.resource && payload.resource.id) {
      return {
        email: payload.resource.payer.email_address,
        order_id: payload.resource.id,
      };
    }
    
    // For Stripe
    if (payload.data && payload.data.object && payload.data.object.customer_email) {
      return {
        email: payload.data.object.customer_email,
        order_id: payload.data.object.payment_intent,
      };
    }
    
    // For Gumroad
    if (payload.email && payload.order_id) {
      return {
        email: payload.email,
        order_id: payload.order_id,
      };
    }
    
    throw new Error('Unsupported payment processor format');
  } catch (error) {
    console.error('Error extracting payment details:', error);
    throw error;
  }
}

// Trigger GitHub Actions workflow
async function triggerGitHubWorkflow(paymentDetails) {
  const endpoint = `https://api.github.com/repos/${GITHUB_REPO_OWNER}/${GITHUB_REPO_NAME}/dispatches`;
  
  try {
    await axios.post(
      endpoint,
      {
        event_type: 'payment-complete',
        client_payload: paymentDetails,
      },
      {
        headers: {
          'Accept': 'application/vnd.github.v3+json',
          'Authorization': `token ${GITHUB_TOKEN}`,
        },
      }
    );
    console.log('GitHub Actions workflow triggered successfully');
    return true;
  } catch (error) {
    console.error('Error triggering GitHub workflow:', error.response?.data || error.message);
    return false;
  }
}

// Webhook endpoint
app.post('/webhook/payment', async (req, res) => {
  console.log('Received webhook:', JSON.stringify(req.body, null, 2));
  
  // Verify webhook signature
  if (!verifyWebhookSignature(req)) {
    console.error('Invalid webhook signature');
    return res.status(401).send('Invalid signature');
  }
  
  try {
    // Extract payment details
    const paymentDetails = extractPaymentDetails(req.body);
    console.log('Extracted payment details:', paymentDetails);
    
    // Make sure we have the necessary data
    if (!paymentDetails.email || !paymentDetails.order_id) {
      throw new Error('Missing required payment details');
    }
    
    // Trigger GitHub Actions workflow
    const success = await triggerGitHubWorkflow(paymentDetails);
    
    if (success) {
      res.status(200).send('Webhook processed successfully');
    } else {
      res.status(500).send('Error processing webhook');
    }
  } catch (error) {
    console.error('Error processing webhook:', error);
    res.status(400).send(`Error: ${error.message}`);
  }
});

// Health check endpoint
app.get('/health', (req, res) => {
  res.status(200).send('Webhook handler is running');
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`Webhook handler listening on port ${PORT}`);
}); 