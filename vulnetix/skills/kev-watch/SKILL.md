---
name: kev-watch
description: Cross-reference CISA/EU KEV (Known Exploited Vulnerabilities) catalogs with installed dependencies. Surfaces actively exploited CVEs hitting this repo.
argument-hint: "[--since YYYY-MM-DD] [--catalog cisa|eu|all]"
user-invocable: true
allowed-tools: Bash, Read, Glob, Grep, Edit, Write
model: sonnet
---

# Vulnetix KEV Watch Skill

Pulls the KEV catalog and intersects with installed packages — the "what's on fire and is it in my repo?" view.

## Step 1: Load capabilities

Read `.vulnetix/capabilities.yaml`. Use `derived.primary_package_manager` to focus the lockfile scan.

## Step 2: Pull KEV catalog

```bash
vulnetix vdb kev list $ARGUMENTS -o json
```

Honor `--since`, `--catalog`. Default `--catalog all`, `--since` = 30 days ago.

## Step 3: Cross-reference repo

For each KEV entry:
1. Extract affected package names.
2. Grep lockfiles for matches (npm: package-lock.json/pnpm-lock.yaml; pypi: poetry.lock/uv.lock; etc.).
3. Mark presence: direct / transitive / not-found.

If `.vulnetix/scans/*.cdx.json` SBOM exists, prefer that for matching.

## Step 4: Render report

```
KEV catalog hits (window: <since>)
Total KEV entries scanned: N | In your repo: M

| CVE | Package | Installed | KEV deadline | Days remaining | Action |
```

Highlight rows where deadline is < 14 days as URGENT.

## Step 5: Suggested follow-ups

- Each in-repo KEV item → `/vulnetix:fix <id>` and `/vulnetix:detection-rules <id>` (if detection stack present)
- Past-deadline items → escalate via `/vulnetix:incident-respond <id>` (agent)

## Memory update

For each in-repo match, ensure a memory entry exists with a `kev_deadline` field and `event: kev-watch` history line.
