// generate_signature.js
const crypto = require('crypto');

// --- CONFIGURATION ---
const secret = 'webhook-secret-key'; // Matches WEBHOOK_SECRET in your .env
const payloadObject = {
  event_type: "payment.completed",
  payment_id: "dd3d664a-0471-44b4-9510-d6cc8a358656",
  provider: "test_provider",
  data: {
    reference: "TEST_REF_456_DEV_OPS"
  }
};

// Canonical, compact JSON string — MUST MATCH EXACTLY what curl sends
const payloadString = JSON.stringify(payloadObject);

// Generate HMAC-SHA256
const hmac = crypto.createHmac('sha256', secret);
hmac.update(payloadString);
const signature = hmac.digest('hex');

// Output for curl use
console.log('--- Signature Generation ---');
console.log('Payload string:', payloadString);
console.log('Signature:', signature);
