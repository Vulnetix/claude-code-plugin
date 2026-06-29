---
name: get-api-key
description: 'Self-serve a free Vulnetix VDB API key — install the CLI if missing, then register an email at the public Community endpoint and store the credentials. Use when a user has no API key, hits unauthenticated rate limits, sees auth_status=unauthenticated, or asks to sign up / get a free key. The VDB also works unauthenticated on a shared pool; a free key raises limits.'
argument-hint: <email (optional — will prompt if omitted)>
user-invocable: true
allowed-tools: Bash
model: sonnet
triggers:
  - "free api key"
  - "get an api key"
  - "get me a key"
  - "register for vulnetix"
  - "sign up for vulnetix"
  - "i have no api key"
  - "unauthenticated rate limit"
chain:
  - auth-login
outputBudget: short
cooldown: per-session
---

# Get a free Vulnetix API key (self-serve)

The Vulnetix VDB works **unauthenticated** on a shared pool — most lookups need no key. A free **Community** key removes the shared-pool contention and raises your daily limit. Registration is a single unauthenticated request: an email in, credentials out. No email confirmation, no captcha. See `_lib/contract.md`.

## 1 · Ensure the CLI is present

The CLI stores and uses the credentials. Install it self-serve if missing:

```bash
command -v vulnetix &>/dev/null || bash "${CLAUDE_PLUGIN_ROOT}/hooks/ensure-vulnetix-cli.sh"
```

If install fails, the key still works over plain HTTP (`Authorization: ApiKey <apiKey>`), but storing it via the CLI is preferred.

## 2 · Skip if already authenticated

```bash
vulnetix auth status -o json 2>/dev/null | jq -r '.status // "unauthenticated"'
```

If this is `authenticated`, stop and report — do **not** register again.

## 3 · Get the user's email (consent required)

Registration creates a real Community account tied to an email address and notifies Vulnetix. **Do not invent an email.** Use the email passed as `$ARGUMENTS`, or ask the user for the one they want the account under. Confirm before proceeding.

## 4 · Register

```bash
EMAIL="<the email>"
RESP=$(curl -fsS -X POST https://www.vulnetix.com/api/site/v1/register \
  -H 'Content-Type: application/json' \
  -d "{\"email\":\"${EMAIL}\"}")
echo "$RESP" | jq '{orgId, hasSecret: (.secret != null)}'
```

- **200** → body is `{ orgId, secret, apiKey, jwt }`. Continue.
- **409** → this email already has an account. Credentials are **not** re-issued here; the user must retrieve their existing key from the dashboard (https://www.vulnetix.com/vdb-console) and run `/vulnetix:auth-login --org-id <id> --secret <secret>`. Stop.
- **400** → invalid email. Re-prompt.

## 5 · Store the credentials

Use the raw `secret` (SigV4) — it maps directly to `--secret`, no parsing:

```bash
ORG=$(echo "$RESP" | jq -r .orgId)
SECRET=$(echo "$RESP" | jq -r .secret)
vulnetix auth login --org-id "$ORG" --secret "$SECRET" --store home
vulnetix auth status -o json 2>/dev/null | jq -r '.status'
```

For raw HTTP (no CLI), the response's `apiKey` is the full header value: `Authorization: ApiKey <apiKey>`.

## 6 · Report

Confirm the stored org id (never echo the full secret), state the tier and that it is active immediately:

- **Tier:** Community (free) — daily request limit applies; the VDB is otherwise fully accessible.
- **Upgrade:** Pro ($25/mo, higher throughput) — https://www.vulnetix.com/pricing

**Privacy:** only the email leaves the machine. No source code is sent. Credentials are written to `~/.vulnetix/credentials.json` (`--store home`).

Next: `/vulnetix:vuln <cve>` to make your first authenticated lookup.
