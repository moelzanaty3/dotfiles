---
name: paymob
description: "Use when integrating Paymob payment processing — creating payment intentions, handling webhooks with HMAC validation, configuring checkout flows (hosted, embedded pixel, mobile SDK), or generating payment links. Covers MENA-region payment methods: cards (Visa/MC/Amex/MADA/OmanNet), digital wallets (Vodafone Cash, Orange Cash, e& money, stcPay, We Pay, Apple Pay, Google Pay), BNPL (Tabby, Tamara, vaLU, Sympl, Halan), and kiosk/cash."
---

# Paymob Integration

> **Attribution:** This skill is built on top of the official Paymob LLM knowledge base published at [paymob.com/llms.txt](https://paymob.com/llms.txt). All API knowledge, integration patterns, and flow documentation originate from Paymob's own documentation. Credit and thanks to the Paymob team for making their docs AI-agent-friendly.

Paymob is the dominant payment processor in the MENA region, operating in Egypt, Saudi Arabia, UAE, Kuwait, Oman, Bahrain, Jordan, and Pakistan.

## When this skill activates

- User mentions "Paymob" or references Paymob credentials (`PAYMOB_SECRET_KEY`, `PAYMOB_PUBLIC_KEY`, `PAYMOB_INTEGRATION_ID`)
- User is building payment flows targeting Egypt, Saudi Arabia, UAE, Kuwait, Oman, Bahrain, Jordan, or Pakistan
- User asks about payment intentions, hosted checkout, embedded checkout, HMAC callbacks, or QuickLinks
- User's codebase contains Paymob API calls or SDK initialization

## Non-negotiable rules

These rules apply to every Paymob integration regardless of what the user asks:

1. **HMAC validation is mandatory** — never process a payment callback without first verifying the HMAC signature. A callback without valid HMAC must be rejected.
2. **Backend webhook = source of truth** — the server-to-server webhook callback (after HMAC verification) is the only authoritative signal for payment status. Frontend redirects and SDK callbacks are UX signals only — never use them to confirm order fulfillment.
3. **Amount is always integer cents** — `10000` = 100.00 EGP. Never use floats or strings.
4. **Integration IDs are environment-specific** — test integration IDs only work with test credentials; live IDs only work with live credentials. Mixing them causes silent 404s.
5. **Secret key is server-side only** — never include it in client-side code, browser bundles, or mobile app source. Exposure allows unauthorized charges on the merchant account.

## Before writing any integration code

Read the relevant reference file for the task at hand:

| Task | Reference |
|------|-----------|
| Setting up credentials and environments | `references/authentication.md` |
| Creating a payment / building the intention request | `references/create-intention.md` |
| Choosing and implementing a checkout flow | `references/payment-flows.md` |
| Receiving and validating payment results | `references/webhooks-hmac.md` |
| Debugging a failing integration | `references/error-handling.md` |

## Quick flow selection guide

| Scenario | Flow |
|----------|------|
| Web app, simplest path, max PCI compliance | Hosted Checkout (redirect) |
| Web app with custom embedded UI | Pixel (iframe) |
| iOS or Android native app | Mobile SDK |
| Automated invoicing or WhatsApp commerce | QuickLink API |
| Manual one-off payment links | Payment Links (dashboard) |
