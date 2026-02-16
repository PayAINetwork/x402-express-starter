# @x402/express Example Server

Express.js server demonstrating how to protect API endpoints with a paywall using the `@x402/express` middleware.

```typescript
import express from "express";
import { paymentMiddleware, x402ResourceServer } from "@x402/express";
import { ExactEvmScheme } from "@x402/evm/exact/server";
import { HTTPFacilitatorClient } from "@x402/core/server";
import { facilitator } from "@payai/facilitator";

const app = express();

app.use(
  paymentMiddleware(
    {
      "GET /weather": {
        accepts: { scheme: "exact", price: "$0.001", network: "eip155:84532", payTo: evmAddress },
        description: "Weather data",
        mimeType: "application/json",
      },
    },
    new x402ResourceServer(new HTTPFacilitatorClient(facilitator))
      .register("eip155:84532", new ExactEvmScheme()),
  ),
);

app.get("/weather", (req, res) => res.json({ weather: "sunny", temperature: 70 }));
```

## Prerequisites

- Node.js v20+ (install via [nvm](https://github.com/nvm-sh/nvm))
- pnpm v10 (install via [pnpm.io/installation](https://pnpm.io/installation))
- Valid EVM and SVM addresses for receiving payments 

## Setup

1. Copy `.env-local` to `.env`:

```bash
cp .env-local .env
```

and fill required environment variables:

- `EVM_ADDRESS` - Ethereum address to receive payments
- `SVM_ADDRESS` - Solana address to receive payments

2. Install and build all packages from the typescript examples root:
```bash
cd ../../
pnpm install && pnpm build
cd servers/express
```

3. Run the server
```bash
pnpm dev
```

## Going to Production

When you're ready to move beyond the free tier, create a merchant account at [merchant.payai.network](https://merchant.payai.network) and set your API key environment variables:

```env
PAYAI_API_KEY_ID=your-api-key-id
PAYAI_API_KEY_SECRET=payai_sk_your-base64-encoded-secret
```

No code changes are needed — the `@payai/facilitator` package automatically picks up these env vars and authenticates all facilitator requests with a JWT Bearer token.

## Testing the Server

You can test the server using one of the example clients:

### Using the Fetch Client
```bash
cd ../clients/fetch
# Ensure .env is setup
pnpm dev
```

### Using the Axios Client
```bash
cd ../clients/axios
# Ensure .env is setup
pnpm dev
```

These clients will demonstrate how to:
1. Make an initial request to get payment requirements
2. Process the payment requirements
3. Make a second request with the payment token

## Example Endpoint

The server includes a single example endpoint at `/weather` that requires a payment of 0.001 USDC on Base Sepolia or Solana Devnet to access. The endpoint returns a simple weather report.

## Response Format

### Payment Required (402)

```
HTTP/1.1 402 Payment Required
Content-Type: application/json; charset=utf-8
PAYMENT-REQUIRED: <base64-encoded JSON>

{}
```

The `PAYMENT-REQUIRED` header contains base64-encoded JSON with the payment requirements.
Note: `amount` is in atomic units (e.g., 1000 = 0.001 USDC, since USDC has 6 decimals):

```json
{
  "x402Version": 2,
  "error": "Payment required",
  "resource": {
    "url": "http://localhost:4021/weather",
    "description": "Weather data",
    "mimeType": "application/json"
  },
  "accepts": [
    {
      "scheme": "exact",
      "network": "eip155:84532",
      "amount": "1000",
      "asset": "0x036CbD53842c5426634e7929541eC2318f3dCF7e",
      "payTo": "0x1c47E9C085c2B7458F5b6C16cCBD65A65255a9f6",
      "maxTimeoutSeconds": 300,
      "extra": {
        "name": "USDC",
        "version": "2",
        "resourceUrl": "http://localhost:4021/weather"
      }
    },
    {
      "scheme": "exact",
      "network": "solana:EtWTRABZaYq6iMfeYKouRu166VU2xqa1",
      "amount": "1000",
      "asset": "4zMMC9srt5Ri5X14GAgXhaHii3GnPAEERYPJgZJDncDU",
      "payTo": "FV6JPj6Fy12HG8SYStyHdcecXYmV1oeWERAokrh4GQ1n",
      "maxTimeoutSeconds": 300,
      "extra": {
        "feePayer": "...",
        "resourceUrl": "http://localhost:4021/weather"
      }
    }
  ]
}
```

### Successful Response

```
HTTP/1.1 200 OK
Content-Type: application/json; charset=utf-8
PAYMENT-RESPONSE: <base64-encoded JSON>

{"report":{"weather":"sunny","temperature":70}}
```

The `PAYMENT-RESPONSE` header contains base64-encoded JSON with the settlement details:

```json
{
  "success": true,
  "transaction": "0x...",
  "network": "eip155:84532",
  "payer": "0x...",
  "requirements": {
    "scheme": "exact",
    "network": "eip155:84532",
    "amount": "1000",
    "asset": "0x036CbD53842c5426634e7929541eC2318f3dCF7e",
    "payTo": "0x...",
    "maxTimeoutSeconds": 300,
    "extra": {
      "name": "USDC",
      "version": "2",
      "resourceUrl": "http://localhost:4021/weather"
    }
  }
}
```

## Extending the Example

To add more paid endpoints, follow this pattern:

```typescript
// First, configure the payment middleware with your routes
app.use(
  paymentMiddleware(
    {
      "GET /your-endpoint": {
        accepts: {
          scheme: "exact",
          price: "$0.10",
          network: "eip155:84532",
          payTo: evmAddress,
        },
        description: "Your endpoint description",
        mimeType: "application/json",
      },
    },
    resourceServer,
  ),
);

// Then define your routes as normal
app.get("/your-endpoint", (req, res) => {
  res.json({
    // Your response data
  });
});
```

**Network identifiers** use [CAIP-2](https://github.com/ChainAgnostic/CAIPs/blob/main/CAIPs/caip-2.md) format, for example:
- `eip155:84532` — Base Sepolia
- `eip155:8453` — Base Mainnet
- `solana:EtWTRABZaYq6iMfeYKouRu166VU2xqa1` — Solana Devnet
- `solana:5eykt4UsFv8P8NJdTREpY1vzqKqZKvdp` — Solana Mainnet

## x402ResourceServer Config

The `x402ResourceServer` uses a builder pattern to register payment schemes that declare how payments for each network should be processed: 

```typescript
const resourceServer = new x402ResourceServer(facilitatorClient)
  .register("eip155:*", new ExactEvmScheme())   // All EVM chains
  .register("solana:*", new ExactSvmScheme())   // All SVM chains
```

## Facilitator Config

The `@payai/facilitator` package provides a pre-configured facilitator that points to `https://facilitator.payai.network` and automatically handles JWT authentication when API keys are set:

```typescript
import { facilitator } from "@payai/facilitator";
import { HTTPFacilitatorClient } from "@x402/core/server";

// Works out of the box on the free tier.
// Set PAYAI_API_KEY_ID + PAYAI_API_KEY_SECRET env vars for authenticated access.
const facilitatorClient = new HTTPFacilitatorClient(facilitator);
```

For explicit credentials or a custom facilitator URL, use `createFacilitatorConfig`:

```typescript
import { createFacilitatorConfig } from "@payai/facilitator";

const facilitatorClient = new HTTPFacilitatorClient(
  createFacilitatorConfig("my-key-id", "payai_sk_...")
);
```

## Next Steps

See [Advanced Examples](../advanced/) for:
- **Bazaar discovery** — make your API discoverable
- **Dynamic pricing** — price based on request context
- **Dynamic payTo** — route payments to different recipients  
- **Lifecycle hooks** — custom logic on verify/settle
- **Custom tokens** — accept payments in custom tokens
