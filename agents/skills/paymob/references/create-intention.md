# Create Intention API

A payment intention is the entry point for every Paymob transaction. Create one on your server before presenting any checkout UI to the customer.

## Endpoint

```
POST https://accept.paymob.com/v1/intention/
Authorization: Token <secret_key>
Content-Type: application/json
```

## Request fields

### Required

| Field | Type | Description |
|-------|------|-------------|
| `amount` | integer | Amount in cents. `10000` = 100.00 EGP. Never a float. |
| `currency` | string | ISO 4217 currency code: `"EGP"`, `"SAR"`, `"AED"`, `"KWD"`, etc. Must match the integration's configured currency. |
| `payment_methods` | array | Integration ID(s) or method name strings identifying which payment methods to offer. |

### Optional — but required by some methods

| Field | Type | Notes |
|-------|------|-------|
| `items` | array of objects | Required for BNPL methods (Tabby, Tamara, vaLU, etc.). Each item: `{name, amount, description, quantity}` |
| `billing_data` | object | `{first_name, last_name, email, phone_number, country, city, street, building, floor, apartment}`. `phone_number` is required for wallet methods (Vodafone Cash, Orange Cash, etc.). |

### Optional — recommended for all integrations

| Field | Type | Notes |
|-------|------|-------|
| `notification_url` | string | Your server endpoint that receives the async webhook callback. Must be publicly reachable. |
| `redirection_url` | string | URL Paymob redirects the customer to after Hosted Checkout completes (success or failure). |
| `special_reference` | string | Your own order/transaction ID for reconciliation. Passed through to callbacks as `obj.special_reference`. |
| `extras` | object | Arbitrary key-value metadata attached to the intention and passed through to callbacks. |

## Minimal request

```
POST /v1/intention/
Authorization: Token <secret_key>
Content-Type: application/json

{
  "amount": 10000,
  "currency": "EGP",
  "payment_methods": [<integration_id>]
}
```

## Response shape

| Field | Type | Description |
|-------|------|-------------|
| `id` | string | Intention ID |
| `client_secret` | string | Used to initialize the Pixel SDK or Mobile SDK on the client side |
| `payment_keys` | array | One object per payment method, containing method-specific initialization data |
| `order` | object | `{id, status}` — Paymob's internal order record |

The `client_secret` is the value you pass to the frontend or mobile app to initialize the checkout UI. It is not a secret in the security sense — it is safe to send to the client.

## Recommended flow

```
1. Customer triggers checkout on your UI
2. Your server calls POST /v1/intention/ with amount, currency, payment_methods
3. Store intention ID and special_reference for reconciliation
4. Return client_secret (and any needed payment_keys data) to your frontend
5. Frontend initializes checkout UI using client_secret
6. Await webhook callback for final payment status (see webhooks-hmac.md)
```

## Notes

- Create a new intention per checkout attempt — do not reuse intentions across sessions
- The intention expires after a configurable period; check Dashboard settings for expiry duration
- `payment_methods` accepts either integration IDs (integers) or method name strings — prefer integration IDs for precision; method name strings depend on merchant configuration
