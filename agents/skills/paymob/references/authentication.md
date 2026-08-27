# Paymob Authentication & Credentials

## The four credentials

Every Paymob integration requires four distinct values. They are not interchangeable.

| Credential | Where it lives | Used for |
|------------|---------------|----------|
| **Secret Key** | Server only — never client | `Authorization` header on all server-to-Paymob API calls |
| **Public Key** | Client-side safe | Initializing the Pixel SDK or Hosted Checkout on the frontend |
| **Integration ID(s)** | Server (in request body) | Identifying which payment method(s) to offer; one ID per method |
| **HMAC Secret** | Server only — never client | Verifying the signature on incoming webhook callbacks |

## Secret Key

Used in the `Authorization` header with a `Token` prefix:

```
Authorization: Token <your_secret_key>
```

- Must only appear in server-side code (environment variables, secrets manager)
- Never include in client bundles, mobile app source, or version control
- Exposure allows unauthorized charges against the merchant account

## Public Key

- Used to initialize the Pixel embedded checkout or to launch the Hosted Checkout flow on the client
- Safe to include in frontend code — it identifies the merchant without granting API access

## Integration IDs

- Numeric identifiers assigned per payment method per merchant account
- Each enabled payment method (card, Vodafone Cash, Apple Pay, Tabby, etc.) has its own integration ID
- Found in: **Paymob Dashboard → Developers → Integration IDs**
- Passing a wrong, unconfigured, or environment-mismatched integration ID returns a `404` from the Create Intention API — this is the most common integration error

## HMAC Secret

Used exclusively for webhook verification. It is separate from the Secret Key.

- Found in: **Paymob Dashboard → Developers → HMAC Secret**
- Used only on the server when verifying incoming webhook callback signatures
- See `webhooks-hmac.md` for the full verification process

## Environments

Paymob provides two fully isolated environments:

| Environment | Purpose |
|-------------|---------|
| **Sandbox** | Development and QA — no real money moves |
| **Production** | Live transactions |

Each environment has its own complete set of credentials (Secret Key, Public Key, Integration IDs, HMAC Secret). These sets are incompatible — test credentials will fail against live integration IDs and vice versa.

Keep environment credentials in separate files (e.g., `.env.development`, `.env.production`) and never copy-paste IDs across environments.

## Where to find credentials

1. Log in to the **Paymob Dashboard**
2. Navigate to **Developers** in the sidebar
3. **API Keys** section: Secret Key and Public Key
4. **Integration IDs** section: per-method numeric IDs
5. **HMAC Secret** section: webhook verification secret

Ensure business verification is complete before production credentials are issued.
