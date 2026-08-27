# Webhooks & HMAC Validation

## Why webhooks are the source of truth

Paymob delivers the authoritative payment result via a server-to-server HTTP POST to your `notification_url`. This callback:

- Cannot be faked by a customer (unlike a URL redirect)
- Arrives even if the customer closes the browser mid-flow
- Is authenticated with an HMAC signature you can verify independently

Frontend redirects and mobile SDK result callbacks are UX signals only — they tell the user something happened, but they must never trigger order fulfillment. Only a webhook with a valid HMAC signature is authoritative.

## HMAC verification

### What Paymob sends

Paymob appends an `hmac` query parameter to the `notification_url`:

```
POST https://your-server.com/webhooks/paymob?hmac=<signature>
```

The POST body contains the full transaction object as JSON.

### How to verify

1. Extract the following fields from the callback body **in this exact order**:
   ```
   amount_cents
   created_at
   currency
   error_occured
   has_parent_transaction
   id
   integration_id
   is_3d_secure
   is_auth
   is_capture
   is_refunded
   is_standalone_payment
   is_voided
   order.id
   owner
   pending
   source_data.pan
   source_data.sub_type
   source_data.type
   success
   ```

2. Concatenate all extracted values into a single string (no separator)

3. Compute `HMAC-SHA512` of that string using your **HMAC Secret** (not the API Secret Key — they are different)

4. Compare your computed hash with the `hmac` query parameter value (case-insensitive hex comparison)

5. If they do not match: reject the request and return HTTP `400`. Do not process the payment.

6. If they match: proceed to check the `success` field

### HMAC Secret location

**Paymob Dashboard → Developers → HMAC Secret**

This is a separate credential from the API Secret Key. Do not confuse them — using the wrong one will always produce a mismatch.

## Validation sequence (enforce this order)

```
1. Receive POST to notification_url
2. Compute HMAC from callback body fields (exact order above)
3. Compare with hmac query parameter
   → Mismatch: return HTTP 400, stop processing
4. Check pending field
   → true: acknowledge (HTTP 200), do not fulfill yet — await the follow-up callback
5. Check success field
   → false: log the failure, update order to failed state, return HTTP 200
   → true: continue
6. Verify amount_cents and currency match the expected order values
7. Check idempotency — has this order already been fulfilled?
   → Already fulfilled: return HTTP 200, stop (do not double-fulfill)
8. Fulfill the order (update database, trigger downstream actions)
9. Return HTTP 200
```

## Key callback fields

| Field | Type | Notes |
|-------|------|-------|
| `success` | boolean | `true` = payment completed successfully |
| `pending` | boolean | `true` = awaiting async confirmation (e.g., kiosk cash payment) — do not fulfill yet |
| `error_occured` | boolean | `true` = payment failed |
| `amount_cents` | integer | Verify this matches your order amount |
| `currency` | string | Verify this matches your order currency |
| `id` | integer | Paymob transaction ID |
| `order.id` | integer | Paymob order ID |
| `obj.special_reference` | string | Your merchant reference passed in the intention |
| `source_data.type` | string | Payment method type (e.g., `"card"`, `"wallet"`) |
| `source_data.sub_type` | string | Payment method subtype (e.g., `"Visa"`, `"Vodafone"`) |
| `is_refunded` | boolean | Whether the transaction has been refunded |

## Idempotency

Paymob may send the same callback more than once (network retries, timeouts). Your handler must be idempotent:

- Check whether the order is already in a fulfilled state before processing
- Use `order.id` or `obj.special_reference` as the idempotency key
- Return HTTP 200 on duplicate callbacks — returning an error causes Paymob to retry

## Pending payments

Some payment methods (kiosk, cash collection) are async — the customer pays at a physical location after the intention is created. For these:

- `pending: true` on the initial callback means "customer has initiated but not yet paid"
- A second callback with `success: true` arrives when the physical payment is confirmed
- Do not fulfill on `pending: true` — wait for `success: true`

## Local development

`notification_url` must be a publicly reachable HTTPS endpoint. For local development:

- Use a tunneling tool (ngrok, Cloudflare Tunnel, localtunnel) to expose your local server
- Set the tunnel URL as `notification_url` when creating the intention
- Never use `localhost` or `127.0.0.1` — Paymob cannot reach them
