# Pix — plugin tasks.
#
# The docs under website/content/docs/{skills,agents,hooks,install} are
# generated. Everything else there is hand-written and carries judgement.

default:
    @just --list

# Regenerate the pages that are a projection of the plugin itself.
gen-docs:
    node scripts/gen-docs.mjs

# Fail if the generated pages have drifted from their sources. CI runs this.
check-docs:
    node scripts/gen-docs.mjs --check

# Validate every skill against the Agent Skills spec.
validate:
    skill-validator check --strict --allow-extra-frontmatter --allow-dirs=evals,references skills/

# Check the eval corpus itself: no model, no credential, no cost.
evals:
    node scripts/eval.mjs

# Drive real agents through the corpus. Costs money and minutes.
evals-full agents="":
    node scripts/eval.mjs --agents{{ if agents != "" { "=" + agents } else { "" } }}

# Record the marketing replays, from the same runs the evals assert on.
record-demos agents="":
    node scripts/record-demos.mjs {{ if agents != "" { "--agents=" + agents } else { "" } }}

# Everything CI checks on a push, in one go.
check: validate check-docs evals

# Serve the docs locally with live reload.
docs-serve:
    cd website && hugo server --buildDrafts --navigateToChanged

# Install the plugin into the coding agents on this machine.
install:
    vulnetix agent install
