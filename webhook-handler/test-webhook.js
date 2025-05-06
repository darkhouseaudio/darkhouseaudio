/**
 * Webhook Test Script
 * 
 * This script simulates a payment processor webhook to test your webhook handler.
 * Run it with: node test-webhook.js
 */

require('dotenv').config();
const axios = require('axios');
const readline = require('readline');

const rl = readline.createInterface({
  input: process.stdin,
  output: process.stdout
});

// Default webhook endpoint (localhost for testing)
const defaultEndpoint = 'http://localhost:3000/webhook/payment';

// Sample webhook payloads for different payment processors
const payloadTemplates = {
  paypal: {
    id: 'WH-123456789',
    event_type: 'PAYMENT.SALE.COMPLETED',
    resource: {
      id: 'PAY-TEST12345',
      payer: {
        email_address: 'customer@example.com'
      }
    }
  },
  stripe: {
    id: 'evt_test_123456',
    type: 'checkout.session.completed',
    data: {
      object: {
        id: 'cs_test_123456',
        customer_email: 'customer@example.com',
        payment_intent: 'pi_test_123456'
      }
    }
  },
  gumroad: {
    email: 'customer@example.com',
    order_id: 'GUMROAD-123456',
    price: 'USD 29.00',
    product_name: 'BleedShift 2'
  }
};

// Function to prompt user for input
function prompt(question) {
  return new Promise((resolve) => {
    rl.question(question, (answer) => {
      resolve(answer);
    });
  });
}

// Main function
async function main() {
  console.log('Webhook Test Script');
  console.log('-------------------');
  
  try {
    // Get webhook endpoint
    const endpoint = await prompt(`Webhook endpoint [${defaultEndpoint}]: `) || defaultEndpoint;
    
    // Choose payment processor
    console.log('\nSelect payment processor:');
    console.log('1. PayPal');
    console.log('2. Stripe');
    console.log('3. Gumroad');
    console.log('4. Custom (enter your own JSON payload)');
    const processorChoice = await prompt('Enter choice (1-4): ');
    
    let payload;
    
    if (processorChoice === '4') {
      // Custom payload
      console.log('\nEnter your JSON payload (end with an empty line):');
      let jsonInput = '';
      let line;
      while ((line = await prompt('')) !== '') {
        jsonInput += line;
      }
      
      try {
        payload = JSON.parse(jsonInput);
      } catch (error) {
        throw new Error(`Invalid JSON: ${error.message}`);
      }
    } else {
      // Use template payload
      const processor = ['paypal', 'stripe', 'gumroad'][parseInt(processorChoice) - 1];
      
      if (!processor) {
        throw new Error('Invalid payment processor selection');
      }
      
      payload = JSON.parse(JSON.stringify(payloadTemplates[processor])); // Clone template
      
      // Customize the payload
      const email = await prompt('\nCustomer email: ');
      const orderId = await prompt('Order ID: ');
      
      if (email) {
        if (processor === 'paypal') {
          payload.resource.payer.email_address = email;
        } else if (processor === 'stripe') {
          payload.data.object.customer_email = email;
        } else {
          payload.email = email;
        }
      }
      
      if (orderId) {
        if (processor === 'paypal') {
          payload.resource.id = orderId;
        } else if (processor === 'stripe') {
          payload.data.object.payment_intent = orderId;
        } else {
          payload.order_id = orderId;
        }
      }
    }
    
    console.log('\nSending webhook payload:');
    console.log(JSON.stringify(payload, null, 2));
    
    // Send the webhook
    const confirm = await prompt('\nSend this webhook? (y/n): ');
    
    if (confirm.toLowerCase() !== 'y') {
      throw new Error('Webhook sending cancelled');
    }
    
    console.log('\nSending webhook...');
    
    const response = await axios.post(endpoint, payload, {
      headers: {
        'Content-Type': 'application/json'
      }
    });
    
    console.log(`\nResponse (${response.status}): ${response.data}`);
    console.log('\nWebhook sent successfully!');
    
    // Remind to check GitHub Actions
    console.log('\nIMPORTANT: Check your GitHub repository Actions tab to verify the workflow was triggered.');
    console.log('Then check your purchases.json file to confirm the new purchase was added.\n');
  } catch (error) {
    console.error('\nError:', error.response?.data || error.message);
  } finally {
    rl.close();
  }
}

// Run the script
main(); 