// ============================================================
//  paypal.service.js  — PayPal Orders REST API v2
//  VETO Legal Emergency App
//  ENV:  PAYPAL_CLIENT_ID | PAYPAL_CLIENT_SECRET | PAYPAL_ENV
// ============================================================

const PAYPAL_BASE =
  process.env.PAYPAL_ENV === 'live'
    ? 'https://api-m.paypal.com'
    : 'https://api-m.sandbox.paypal.com';

function assertPayPalConfigured() {
  const id = process.env.PAYPAL_CLIENT_ID?.trim();
  const secret = process.env.PAYPAL_CLIENT_SECRET?.trim();
  if (!id || !secret) {
    const err = new Error('PayPal keys missing in server configuration');
    err.code = 'PAYPAL_CONFIG_MISSING';
    throw err;
  }
}

// ── Helper: get OAuth2 token ─────────────────────────────────
async function _getToken() {
  assertPayPalConfigured();
  const creds = Buffer.from(
    `${process.env.PAYPAL_CLIENT_ID}:${process.env.PAYPAL_CLIENT_SECRET}`,
  ).toString('base64');

  const res = await fetch(`${PAYPAL_BASE}/v1/oauth2/token`, {
    method: 'POST',
    headers: {
      Authorization: `Basic ${creds}`,
      'Content-Type': 'application/x-www-form-urlencoded',
    },
    body: 'grant_type=client_credentials',
  });

  const data = await res.json();
  if (!res.ok)
    throw new Error(
      `PayPal token error: ${data.error_description || JSON.stringify(data)}`,
    );
  return data.access_token;
}

// ── Create a one-time order ──────────────────────────────────
/**
 * @param {string} amount      e.g. "5.50"
 * @param {string} currency    e.g. "USD"
 * @param {string} description
 * @param {string} returnUrl
 * @param {string} cancelUrl
 * @returns {{ orderId: string, approveUrl: string }}
 */
async function createOrder(amount, currency, description, returnUrl, cancelUrl) {
  const token = await _getToken();

  const res = await fetch(`${PAYPAL_BASE}/v2/checkout/orders`, {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${token}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      intent: 'CAPTURE',
      purchase_units: [
        {
          amount: { currency_code: currency, value: amount },
          description,
        },
      ],
      application_context: {
        return_url: returnUrl,
        cancel_url: cancelUrl,
        brand_name: 'VETO Legal',
        locale: 'he-IL',
        user_action: 'PAY_NOW',
        shipping_preference: 'NO_SHIPPING',
      },
    }),
  });

  const data = await res.json();
  if (!res.ok)
    throw new Error(
      `PayPal createOrder error: ${JSON.stringify(data.details ?? data.message ?? data)}`,
    );

  const approveUrl = data.links?.find((l) => l.rel === 'approve')?.href;
  if (!approveUrl) throw new Error('PayPal: no approve link in response');

  return { orderId: data.id, approveUrl };
}

// ── Capture an approved order ────────────────────────────────
/**
 * @param {string} orderId
 * @returns {{ success: boolean, captureId: string | null, status: string }}
 */
async function captureOrder(orderId) {
  const token = await _getToken();

  const res = await fetch(
    `${PAYPAL_BASE}/v2/checkout/orders/${orderId}/capture`,
    {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${token}`,
        'Content-Type': 'application/json',
      },
    },
  );

  const data = await res.json();
  if (!res.ok)
    throw new Error(
      `PayPal captureOrder error: ${JSON.stringify(data.details ?? data.message ?? data)}`,
    );

  const captureId =
    data.purchase_units?.[0]?.payments?.captures?.[0]?.id ?? null;

  return {
    success: data.status === 'COMPLETED',
    captureId,
    status: data.status,
    raw: data,
  };
}

async function paypalJson(path, options = {}) {
  const token = await _getToken();
  const res = await fetch(`${PAYPAL_BASE}${path}`, {
    ...options,
    headers: {
      Authorization: `Bearer ${token}`,
      'Content-Type': 'application/json',
      ...(options.headers || {}),
    },
  });
  const data = await res.json().catch(() => ({}));
  if (!res.ok) {
    throw new Error(
      `PayPal API error: ${JSON.stringify(data.details ?? data.message ?? data)}`,
    );
  }
  return data;
}

async function createBillingSubscription({
  planId,
  customId,
  returnUrl,
  cancelUrl,
  brandName = 'VETO Legal',
}) {
  if (!planId) {
    const err = new Error('PayPal billing plan id is missing');
    err.code = 'PAYPAL_PLAN_MISSING';
    throw err;
  }

  const data = await paypalJson('/v1/billing/subscriptions', {
    method: 'POST',
    body: JSON.stringify({
      plan_id: planId,
      custom_id: customId,
      application_context: {
        brand_name: brandName,
        locale: 'he-IL',
        shipping_preference: 'NO_SHIPPING',
        user_action: 'SUBSCRIBE_NOW',
        return_url: returnUrl,
        cancel_url: cancelUrl,
      },
    }),
  });

  const approveUrl = data.links?.find((l) => l.rel === 'approve')?.href;
  if (!approveUrl) throw new Error('PayPal: no approve link in subscription response');
  return { subscriptionId: data.id, approveUrl, status: data.status };
}

async function getBillingSubscription(subscriptionId) {
  return paypalJson(`/v1/billing/subscriptions/${encodeURIComponent(subscriptionId)}`, {
    method: 'GET',
  });
}

async function verifyWebhookSignature({ transmissionId, transmissionTime, certUrl, authAlgo, transmissionSig, webhookId, event }) {
  if (!webhookId) return { verification_status: 'SKIPPED' };
  return paypalJson('/v1/notifications/verify-webhook-signature', {
    method: 'POST',
    body: JSON.stringify({
      auth_algo: authAlgo,
      cert_url: certUrl,
      transmission_id: transmissionId,
      transmission_sig: transmissionSig,
      transmission_time: transmissionTime,
      webhook_id: webhookId,
      webhook_event: event,
    }),
  });
}

module.exports = {
  createOrder,
  captureOrder,
  createBillingSubscription,
  getBillingSubscription,
  verifyWebhookSignature,
};
