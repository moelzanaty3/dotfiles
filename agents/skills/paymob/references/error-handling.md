# Paymob Error Handling & Debugging

## 404 on Create Intention

**Symptom:** `POST /v1/intention/` returns `404`

**Cause:** The `payment_methods` array contains an integration ID that:
- Does not exist in the merchant account
- Has not been configured/activated for this merchant
- Belongs to the wrong environment (e.g., a live integration ID used with test credentials)

**Fix:**
1. Open **Paymob Dashboard → Developers → Integration IDs**
2. Confirm the integration ID exists and is active
3. Confirm the ID belongs to the same environment as your credentials (test vs. live)
4. Check that the payment method associated with the ID is enabled for the merchant account

---

## 400 — Missing or Invalid Fields

**Symptom:** `POST /v1/intention/` returns `400`

Common causes:

| Cause | Fix |
|-------|-----|
| `items` missing when using BNPL (Tabby, Tamara, vaLU, Sympl, Halan, MOGO) | Add `items` array with `{name, amount, description, quantity}` for each line item |
| `billing_data.phone_number` missing when using wallet methods (Vodafone Cash, Orange Cash, etc.) | Add `phone_number` to `billing_data` |
| `currency` does not match the integration's configured currency | Verify the integration's currency in the Dashboard; use the exact ISO 4217 code |
| `amount` is a float or string | Use an integer. `100.00 EGP` → `10000` |
| `payment_methods` is empty | Include at least one integration ID |

---

## Environment Mismatch

**Symptom:** Authentication errors, unexpected 404s, or payments appearing in the wrong Dashboard environment

**Cause:** Test credentials (`secret_key`, `public_key`) mixed with live integration IDs, or vice versa

**Fix:**
- Keep `.env.development` and `.env.production` (or equivalent) strictly separate
- Never copy-paste integration IDs or API keys between environment files
- The Dashboard clearly labels which environment each credential belongs to — double-check before going live

---

## Payment Method Not Enabled

**Symptom:** Method appears in the `payment_methods` request, but customers cannot select it at checkout, or it silently fails

**Cause:** The payment method has not been activated for the merchant account by Paymob

**Fix:**
1. Check **Paymob Dashboard → Payment Methods** to see which methods are active
2. Contact Paymob support to enable the required method
3. Some methods (Apple Pay, BNPL providers) require additional onboarding or agreements

---

## HMAC Mismatch

**Symptom:** Your computed HMAC never matches the `hmac` query parameter on incoming callbacks

Common causes and fixes:

| Cause | Fix |
|-------|-----|
| Using the API Secret Key instead of the HMAC Secret | They are different. HMAC Secret is at **Dashboard → Developers → HMAC Secret** |
| Wrong field order in concatenation | Order is exact — see `webhooks-hmac.md` for the required field list |
| Missing fields in concatenation | All 20 fields must be included; missing any breaks the hash |
| Fields from nested objects not extracted correctly | `order.id`, `source_data.pan`, `source_data.sub_type`, `source_data.type` must be extracted from nested objects |
| Wrong hashing algorithm | Must be HMAC-SHA512 |
| Encoding mismatch | Ensure string values are treated as plain strings; boolean/integer fields should be converted to their string representation (`"true"`, `"false"`, `"10000"`) |

---

## Webhook Callback Not Received

**Symptom:** Payment completes but `notification_url` receives no request

**Cause:** `notification_url` is not publicly reachable

**Fix:**
- `localhost` and `127.0.0.1` are unreachable from Paymob's servers
- For development: use ngrok, Cloudflare Tunnel, or localtunnel to expose a public URL
- For staging/production: deploy the webhook handler to a publicly accessible server before testing
- Verify the URL responds to POST requests with HTTP 200
- Check for firewall or reverse-proxy rules that might block incoming requests

---

## 3D Secure Failures

**Symptom:** Card payments fail during 3DS authentication

**Cause:** Customer's bank declined 3DS, or the 3DS flow was not completed (e.g., customer closed the browser)

**Fix:**
- This is a customer-side event, not an integration bug
- The webhook callback will arrive with `success: false` and `error_occured: true`
- Prompt the customer to retry or use a different card/method
- Do not retry the same intention — create a new intention for a new attempt

---

## Double Fulfillment

**Symptom:** Orders fulfilled twice from the same payment

**Cause:** Webhook handler is not idempotent — Paymob retries callbacks on timeout or error

**Fix:**
- Before fulfilling, check whether the order is already in a fulfilled state
- Use `order.id` or `obj.special_reference` as the idempotency key
- Always return HTTP 200 for callbacks you've already processed — returning an error causes Paymob to retry
