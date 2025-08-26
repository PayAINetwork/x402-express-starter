# x402 Express Starter

Starter for running an x402 Express server.

You can find the upstream example at [coinbase/x402 → examples/typescript/servers/express](https://github.com/coinbase/x402/tree/main/examples/typescript/servers/express).

## Getting Started

### Requirements

- **Node.js**: 18 or newer

### Create a new app using the template

Use your preferred package manager to scaffold:

#### npm (npx)
```bash
npm exec @payai/x402-express-starter -- my-x402-app
```

#### pnpm
```bash
pnpm dlx @payai/x402-express-starter my-x402-app
```

#### bun
```bash
bunx @payai/x402-express-starter my-x402-app
```

Then inside your new app:

```bash
npm run dev
```

### How the created server example works

When you run the generated app, `index.ts` will:

- Load environment variables from `.env` (for example: `PORT`, `PAID_URL`, `PRIVATE_KEY`).
- Create an Express server and apply x402 payment handling using `x402-express` (middleware/utilities).
- Expose example routes that require payment and respond with JSON.
- Log two things to the console:
  - The responses sent to the client
  - Decoded x402 payment metadata (useful for inspecting receipts/headers)


## The Starter Itself

Below are notes on the starter itself, which creates the example that devs use to get started.

### How sync works

- Workflow: `.github/workflows/sync.yml`
- Triggered hourly (cron) and on manual dispatch.
- Steps (high level):
  - Sparse clone upstream `coinbase/x402` and restrict to `examples/typescript/servers/express`.
  - Resolve latest `x402-express` version from npm (best-effort).
  - Mirror files into `vendor/upstream/` (transient; ignored in git and cleaned up).
  - Run `scripts/sanitize.sh` to:
    - Copy all files from `vendor/upstream/` into `template/` (root of the template), preserving structure.
    - Refresh `NOTICE` with the upstream commit and clean up `vendor/` and `upstream/` directories.
  - Inject the resolved `x402-express` version into `template/package.json` (replacing any workspace reference).
  - Open a PR with the changes using `peter-evans/create-pull-request`.

Notes:

- If `npm view x402-express version` fails, the workflow falls back to `0.0.0` and will skip injecting the dependency until it is available.
- The template mirrors the upstream example at the template root (no `src/` in the template). Your generated app runs from its root.

### Local development of this starter

```bash
# run the sanitize/mapping script locally (after an upstream sync or manual vendor update)
scripts/sanitize.sh examples/typescript/servers/express <commit-sha>
```

Key files:

- `template/` – shipped starter template; mirrors upstream example at root
- `vendor/upstream/` – transient mirror used during sync (gitignored and cleaned)
- `.github/workflows/sync.yml` – sync/PR workflow
- `scripts/sanitize.sh` – maps upstream example into `template/` (root)
- `bin/create.js` – CLI that scaffolds a new project from `template/`

### Releasing this starter to npm (optional)

- The `Release` workflow publishes on pushes to `main`.
- Requires `NPM_TOKEN` secret configured in the repo.

### License and attribution

Apache-2.0. Portions are derived from `coinbase/x402` (see `NOTICE`, `LICENSE`, and upstream notices).

# x402-express-starter
Create an x402 Express server merchant in less than 2 minutes!
