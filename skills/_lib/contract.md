# Pix skill contract

Every Pix skill inherits this. Skill bodies reference it (`See _lib/contract.md`)
rather than restating it.

---

## 1. How to reach Vulnetix

There are two surfaces and one order of preference. Take the first that applies.

**1. MCP.** If tools named `vulnetix_*` are in your tool list, use them. They are
the data surface: one URL, no install, already shaped. `vulnetix_vuln`,
`vulnetix_exploits`, `vulnetix_kev_status`, `vulnetix_package_search` and 27 more.

**2. The CLI.** Otherwise use `vulnetix` on PATH. It is the only surface that can
read the working tree, edit a manifest, or run without credentials — so anything
in this library that touches the repository uses it even when MCP is available.

**3. Install it.** If neither is present:

```bash
command -v vulnetix >/dev/null 2>&1 || {
  brew install Vulnetix/tap/vulnetix 2>/dev/null ||
  scoop install vulnetix 2>/dev/null ||
  nix profile install github:Vulnetix/cli 2>/dev/null ||
  curl -fsSL https://cli.vulnetix.com/install.sh | sh
}
```

Then `vulnetix agent install`, which wires this machine's agents up properly —
hooks in each host's own dialect, skills in each host's real directory, and the
MCP server configured where the host speaks MCP.

**4. Credentials.** The CLI finds them itself, in this order: `VULNETIX_API_TOKEN`;
`VULNETIX_API_KEY` + `VULNETIX_ORG_ID`; `VVD_ORG` + `VVD_SECRET`;
`./.vulnetix/credentials.json`; `~/.vulnetix/credentials.json`; the OS keyring;
`.netrc`. Do not re-derive this and do not ask the user for a key you could have
found.

**5. With none of those, it still works.** The CLI falls back to built-in
Community credentials. Reads work; the rate limit is shared with every other
anonymous caller and scans produce no stored snapshot. Say so once, in these
words, rather than presenting it as an error:

> Running on the shared Community tier — reads work, rate limits are shared, and
> scans produce no stored snapshot. A free Community key with its own quota:
> https://www.vulnetix.com/resolve/register, then `vulnetix auth login`.

`vulnetix auth login` runs a browser device grant: it prints a URL and a code that
expires in five minutes, then blocks until the user approves. **You cannot
complete it for them.** Surface the URL and code verbatim and wait. There is no
endpoint that mints a credential from an email address — do not ask for one, and
do not invent one. Skip it entirely if `vulnetix auth status` already says
authenticated.

An agent with MCP has a third option: `vulnetix_auth_start` and
`vulnetix_auth_poll` run the same grant with no CLI at all.

---

## 2. What a skill is for

A skill earns its place when it needs **the repository**, needs **the user**, or
needs **a sequence** the model would not compose correctly on its own.

Looking a fact up is none of those. There were eleven skills here that wrapped a
single lookup, and each was a third copy of a job the MCP tool and the CLI
subcommand already did — three descriptions competing for the same question. They
are gone. Their content lives on as MCP prompts, which is the right shape for a
procedure with no local half.

So: no skill in this library exists to fetch a record. If that is all you need,
call the tool.

---

## 3. Output shaping is the surface's job, not yours

A raw VDB response is large — a single vulnerability record can exceed 2 MB — and
must never reach a model whole.

This used to be the skill's problem, solved with a jq filter library and an
invocation form that hard-coded `${CLAUDE_PLUGIN_ROOT}`. That variable is set only
by Claude Code, and only for plugin-loaded skills, so on the other forty agents
the path was empty, `jq -f` failed, the pipeline produced nothing, and the skill
reported *no data found* rather than an error. Thirty-one of thirty-three skills
were broken that way on every host but one.

Both surfaces now shape their own output:

- MCP tools return shaped records with a declared output schema. `vulnetix_vuln`
  takes `detail: summary | full | raw`; summary is the default and is about 10 KB.
- The CLI's `-o json` output is already projected for exactly this.

Do not write jq pipelines in a skill body. If output is still too large, ask the
surface for less.

---

## 4. Least privilege

`allowed-tools` is a grant that skips the permission prompt for the invoking turn,
so it is scoped to what the skill actually runs:

```yaml
# a skill that only reads
allowed-tools: Bash(vulnetix:*) Read Grep Glob
# a skill that edits manifests
allowed-tools: Bash(vulnetix:*) Read Grep Glob Edit
```

No skill gets bare `Bash`. No read-only skill gets `Write`. A security vendor
shipping the broadest grant available, in a year when a third of audited public
skills were found to carry a flaw, is not a defensible position.

---

## 5. Frontmatter

The Agent Skills spec fixes the top-level keys to `name`, `description`,
`license`, `compatibility`, `metadata` and `allowed-tools`. Anything else this
plugin wants goes under `metadata`, where the spec allows arbitrary values:

```yaml
---
name: <kebab-case>
description: <one sentence, action-oriented, says when to use it>
license: Apache-2.0
allowed-tools: Bash(vulnetix:*) Read Grep Glob
metadata:
  outputBudget: short        # short | medium | long
  chain: [<skill>, <skill>]  # typical follow-ups
---
```

Claude-Code-only keys (`argument-hint`, `user-invocable`, `model`) may stay: other
hosts ignore them.

`triggers:` is gone. It was read by one thing, `prompt-router.sh`, and that hook
no longer exists — a skill is selected by its `description`, which is why the
description has to say *when to use this*, not only what it does.

---

## 6. Output style

- Markdown. The harness renders it; there is no "render report" step.
- Default budget **short**: 30 lines. `medium` may reach 80. `long` is unbounded.
- Tables for ranked or scored data, bullets for unordered findings.
- A diagram only where it earns its space — a timeline, a kill chain. Not for
  three numbers.
- One trailing suggestion at most: ``Next: `verify-fix CVE-…` ``. Not a playbook.

---

## 7. Memory

`.vulnetix/memory.yaml` is the durable record. Write to it only for a decision the
user would expect to find later.

- Mutating skills (`fix`, `dep-resolve`, `verify-fix`) append a `history` event.
- Read-only skills write nothing.
- A skill making inner CLI calls passes `--disable-memory` on them and does one
  consolidated write at the end, so concurrent inner calls cannot race.

`vulnetix agent hook` reads this file at SessionStart to tell the agent what the
last scan found, so what a skill records is what the next session opens with.

---

## 8. Capabilities

`.vulnetix/capabilities.yaml` records which tools this machine has and which
project markers this repository has. Read it to scope yourself — do not offer a
container workflow in a repository with no container files, and do not reach for a
binary that is not installed.

`vulnetix agent capabilities` writes it. It was a shell hook until it moved into
the CLI, which is also when it started being right: the old detector tested for
the `.github/workflows` directory, so a repository with an empty one reported CI
it did not have.

| Field | Use |
|---|---|
| `derived.primary_package_manager` | which manifest to parse |
| `derived.has_containers` / `has_iac` / `has_ci` | whether a subsystem applies |
| `derived.detection_stack` / `sbom_stack` | which tools to compose with |
| `derived.auth_status` | `community` means shared limits — see §1 |
| `binaries.<name>` | gate any compose-with-tool step |

---

## 9. Verification

A change to this library is verified by running it, not by reading it. The eval
corpus under each skill's `evals/` is executed against `vulnetix-fixture-app`,
whose `.vulnetix/expected.json` pins the finding counts, the CVEs, KEV membership
and the manifest line each package anchors to. A rule change that breaks a skill
fails that fixture in three repositories at once, which is the point.
