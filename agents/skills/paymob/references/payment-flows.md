# Paymob Payment Flows

## Flow selection

| Scenario | Recommended flow |
|----------|-----------------|
| Web app, simplest integration, maximum PCI compliance | Hosted Checkout |
| Web app with custom embedded UI (no full redirect) | Pixel (embedded) |
| iOS or Android native app | Mobile SDK |
| Automated invoicing, WhatsApp/social commerce | QuickLink API |
| Manual one-off links (no code) | Payment Links (dashboard) |

---

## Hosted Checkout (Redirect)

The customer is redirected to a Paymob-hosted payment page. Paymob handles all card data entry — the merchant's server never touches card numbers.

**Best for:** server-rendered apps, merchants who want the fastest PCI-compliant path, any case where a full-page redirect is acceptable.

**Flow:**
1. Server creates intention with `notification_url` and `redirection_url`
2. Server receives `client_secret` in the response
3. Server redirects customer to Paymob hosted checkout URL (constructed using `client_secret`)
4. Customer completes payment on Paymob's page
5. Paymob redirects customer to `redirection_url` with query params (UX signal only — do not use to confirm payment)
6. Paymob sends server-to-server webhook to `notification_url` with the final result
7. Server verifies HMAC, updates order state (see `webhooks-hmac.md`)

---

## Pixel (Embedded Checkout)

Paymob's JavaScript SDK renders a payment form inline on the merchant's page. The customer never leaves the site.

**Best for:** SPAs, custom checkout UX, merchants who want branded continuity without building a card form.

**Flow:**
1. Server creates intention, returns `client_secret` to frontend
2. Frontend loads Paymob's Pixel JS snippet
3. Frontend initializes Pixel with `client_secret`
4. Pixel renders the payment form in a designated container
5. Customer submits payment within the iframe
6. Paymob processes the transaction
7. Pixel fires a client-side callback (UX only — display success/error state)
8. Paymob sends server-to-server webhook to `notification_url`
9. Server verifies HMAC, updates order state (see `webhooks-hmac.md`)

**Note:** The Pixel JS URL and initialization parameters are provided in the Paymob Dashboard under the integration's configuration.

---

## Mobile SDK (iOS / Android)

Native SDK presents a payment sheet within the app. Supports the full Paymob payment method roster on mobile.

**Best for:** native iOS and Android apps.

**Flow:**
1. User taps "Pay" in the mobile app
2. App calls your backend endpoint
3. Backend creates intention, returns `client_secret` to the app
4. App initializes the Paymob Mobile SDK with `client_secret`
5. SDK presents a native payment sheet (handles card entry, 3D Secure, wallet flows)
6. Paymob processes the transaction
7. SDK returns a result object to the app (for UX only — do not use to confirm fulfillment)
8. Paymob sends server-to-server webhook to `notification_url`
9. Backend verifies HMAC, updates order state (see `webhooks-hmac.md`)

**Critical:** The SDK result returned to the app is not authoritative. A network interruption between Paymob and the app could produce a misleading SDK result while the actual webhook tells the truth. Always fulfill orders based on the verified webhook.

---

## QuickLink API (Programmatic Payment Links)

Create shareable payment links via API — useful for automation, CRMs, invoicing systems, and WhatsApp commerce bots.

**Best for:** programmatic link generation, invoicing flows, non-interactive payment collection.

**Create a link:**
```
POST https://accept.paymob.com/v1/intention/quick-link/
Authorization: Token <secret_key>
Content-Type: application/json

{
  "amount": 10000,
  "currency": "EGP",
  "payment_methods": [<integration_id>],
  "notification_url": "<your_webhook_url>"
}
```

Response includes a `payment_link` URL ready to share.

**Cancel a link:**
```
DELETE https://accept.paymob.com/v1/intention/quick-link/<link_id>/
Authorization: Token <secret_key>
```

Only unpaid links can be cancelled. Payment result is delivered via webhook (same HMAC verification applies).

---

## Payment Links (Dashboard — No Code)

Create one-off payment links manually in the Paymob Dashboard:

1. Dashboard → **Create** → **Quick Link**
2. Configure: amount, currency, payment methods, expiry, description
3. Copy the generated URL and share it (WhatsApp, email, SMS)

No API calls needed. Suitable for non-technical team members. Results visible in the Dashboard transaction log.
