---
name: manifest-edit-gate
description: 'PreToolUse Edit/Write hook: detect edits to dependency manifests (package.json, requirements.txt, go.mod, pom.xml, Cargo.toml, composer.json, Gemfile, *.csproj, etc.); run a quick risk check on packages being added or modified. Use when guarding casual manifest edits without blocking.'
event: message:preprocessed
---

# Manifest-Edit-Gate hook

## Use when

- An Edit/Write tool call targets a known manifest filename.
- The new dep was not already warned-about this session.


Intercepts file write operations targeting dependency manifests and runs the Vulnetix manifest edit scan.

## Edge cases & gotchas

- Detection is by filename match; non-standard manifest paths are missed.
- Diff extraction is line-based; complex JSON edits (key renames) may extract incorrectly.
- Lock file edits (package-lock.json, etc.) are NOT scanned — too noisy.
- Exit 0 always; never blocks the edit.
- Cooldown by `<manifest_path>:<package>` so repeated edits to different packages in the same file all warn.
