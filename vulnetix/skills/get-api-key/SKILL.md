---
name: get-api-key
description: 'Self-serve a free Vulnetix VDB API key — install the CLI if missing, then run the browser device login so the user approves a code and the CLI stores the credential. Use when a user has no API key, hits unauthenticated rate limits, sees auth_status=unauthenticated, or asks to sign up / get a free key. Needs the user at a browser. The VDB also works unauthenticated on a shared pool; a free key raises limits.'
argument-hint: (none — sign-in happens in the browser)
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

The Vulnetix VDB works **unauthenticated** on a shared pool — most lookups need no key. A free **Community** key removes the shared-pool contention and raises your daily limit. Getting one is a browser device login: the CLI prints a code, the user approves it while signed in to Vulnetix, and the CLI stores the credential. See `_lib/contract.md`.

**This is interactive.** There is no unauthenticated endpoint that mints credentials from an email — identity moved to the Vulnetix identity provider, so a human has to sign in and approve.

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

## 3 · Tell the user what will happen (consent required)

This needs a browser: the user signs in to Vulnetix and approves a short code. **You cannot complete this on their behalf.** Say so before starting, so they are at the keyboard.

No email argument is needed — identity is handled by the Vulnetix sign-in page, which supports password, GitHub, Google and passkeys. A user with no account can create one from the same page. `$ARGUMENTS` is ignored.

## 4 · Start the device login

```bash
vulnetix auth login --store home
```

It prints an approval URL and a code, then waits:

```
Open this URL in a browser:

  https://www.vulnetix.com/cli-login-code?user_code=XXXX-YYYY

Verify this code matches the one shown in your browser:

  XXXX-YYYY

Waiting for browser authorization...
```

**Surface that URL and code to the user verbatim** and ask them to approve. The command blocks until they do, and the code expires after 5 minutes — if it expires, run it again for a fresh one.

The CLI stores the credential itself on success. There is no separate store step and nothing for you to copy.

- **Expired / not approved** → re-run. Do not retry more than twice without asking.
- **Cannot open a browser at all** → the user can sign in at https://www.vulnetix.com/vdb-console and create an API key from the account page, then `/vulnetix:auth-login`.

## 5 · Confirm

```bash
vulnetix auth status -o json 2>/dev/null | jq -r '.status'
```

Expect `authenticated`. If not, report the failure rather than retrying blindly.

## 6 · Report

Confirm the stored org id (never echo the full secret), state the tier and that it is active immediately:

- **Tier:** Community (free) — daily request limit applies; the VDB is otherwise fully accessible.
- **Upgrade:** Pro ($25/mo, higher throughput) — https://www.vulnetix.com/pricing

**Privacy:** only the email leaves the machine. No source code is sent. Credentials are written to `~/.vulnetix/credentials.json` (`--store home`).

Next: `/vulnetix:vuln <cve>` to make your first authenticated lookup.
