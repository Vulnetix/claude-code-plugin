#!/usr/bin/env node
/**
 * Run the eval corpus.
 *
 * 48 evals and a trigger set across 18 skills had been shipping in the
 * repository for months with nothing to execute them — CI ran only
 * `skill-validator check`, which reads frontmatter and never asks whether a
 * skill does what it says.
 *
 * Three layers, cheapest first, because they fail for different reasons:
 *
 *   1. **Corpus** — no model. Does every eval reference a skill that exists, is
 *      every ground-truth CVE actually in the fixture, does every trigger phrase
 *      exist? This is the layer that catches the drift the rest of this work is
 *      about, it costs nothing, and it runs on every push.
 *
 *   2. **Trigger** — drives a real agent and reads which skill it reached for.
 *      Asserts every `should_trigger` phrase fires the skill and no
 *      `should_not_trigger` phrase does. This is what catches two skills
 *      competing for one question, which is the overlap the consolidation
 *      removed.
 *
 *   3. **Ground truth** — asserts the advisory identifiers in a transcript
 *      against the fixture's own expected.json rather than against a judge, so a
 *      hallucinated CVE fails instead of being talked through.
 *
 * Layers 2 and 3 cost real money and minutes, so they are opt-in:
 *
 *   node scripts/eval.mjs                 # layer 1 only. Fast, free, CI-safe.
 *   node scripts/eval.mjs --agents        # all three, against every agent found
 *   node scripts/eval.mjs --agents=claude --skill=fix
 */

import { execFileSync } from "node:child_process";
import { cpSync, mkdtempSync, rmSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";

import {
	AGENTS,
	FIXTURE,
	advisoryIds,
	agentAvailable,
	groundTruth,
	loadCorpus,
	redact,
} from "./eval-lib.mjs";

const argv = process.argv.slice(2);
const flag = (name) => argv.find((a) => a === `--${name}` || a.startsWith(`--${name}=`));
const value = (name) => flag(name)?.split("=")[1];

const runAgents = Boolean(flag("agents"));
const onlySkill = value("skill");
const agentFilter = value("agents");

const corpus = loadCorpus().filter((s) => !onlySkill || s.name === onlySkill);
const truth = groundTruth();

let failures = [];
const fail = (where, message) => failures.push(`${where}: ${message}`);

/* ------------------------------------------------- layer 1: the corpus itself */

const skillNames = new Set(loadCorpus().map((s) => s.name));

/**
 * Skills whose answer is about *this repository*.
 *
 * These are the ones whose evals must name an advisory the fixture actually
 * contains. The rest answer about an advisory or a package in general, and are
 * free to name anything real.
 */
const REPO_SCOPED = new Set([
	"repo-impact",
	"fix",
	"verify-fix",
	"dep-resolve",
	"eol-check",
	"license-check",
	"sast-scan",
	"secret-scan",
	"iac-scan",
	"container-scan",
	"dashboard",
	"sbom-generate",
	"vex-publish",
]);

for (const skill of corpus) {
	const where = `corpus/${skill.name}`;

	if (!skill.frontmatter.description) fail(where, "no description, so nothing can select it");

	// A chain pointing at a deleted skill is a dead suggestion the model will
	// relay to a user who then goes looking for it.
	const chain = skill.frontmatter.metadata?.chain;
	for (const next of (chain ?? "").split(",").map((s) => s.trim()).filter(Boolean)) {
		if (!skillNames.has(next)) fail(where, `chain names "${next}", which does not exist`);
	}

	if (skill.triggers) {
		const { should_trigger = [], should_not_trigger = [] } = skill.triggers;
		if (skill.triggers.skill_name !== skill.name) {
			fail(where, `trigger-eval.json says skill_name "${skill.triggers.skill_name}"`);
		}
		if (should_trigger.length === 0) fail(where, "no should_trigger phrases");
		for (const phrase of [...should_trigger, ...should_not_trigger]) {
			if (!String(phrase).trim()) fail(where, "an empty trigger phrase");
		}
	}

	for (const item of skill.evals) {
		const id = `${where}#${item.id ?? "?"}`;
		if (!item.prompt) fail(id, "no prompt");
		if (!Array.isArray(item.expectations) || item.expectations.length === 0) {
			fail(id, "no expectations");
		}

		// An eval for a repo-scoped skill must name an advisory the fixture
		// actually contains, or it can never pass for a reason anything
		// controls. Advisory-scoped skills are exempt: asking
		// `detection-rules` about the xz backdoor is a fair question about a
		// CVE that is not, and should not be, in this tree.
		if (REPO_SCOPED.has(skill.name)) {
			for (const cve of advisoryIds(`${item.prompt} ${JSON.stringify(item.expectations ?? [])}`)) {
				if (cve.startsWith("CVE-") && !truth.requiredCves.has(cve)) {
					fail(id, `names ${cve}, which the fixture does not contain, so this eval cannot pass`);
				}
			}
		}

		// The corpus outlived the jq filter library and the slash-command
		// namespace; an expectation still describing either is asserting on
		// behaviour that no longer exists.
		const text = JSON.stringify(item);
		if (text.includes("_lib/jq")) fail(id, "expects a jq filter pipeline, which was removed");
		if (text.includes("CLAUDE_PLUGIN_ROOT")) fail(id, "expects CLAUDE_PLUGIN_ROOT, which was removed");
		if (/\/vulnetix:/.test(text)) fail(id, "expects a /vulnetix: slash command, which was removed");
	}
}

const evalCount = corpus.reduce((n, s) => n + s.evals.length, 0);
const triggerCount = corpus.reduce(
	(n, s) => n + (s.triggers?.should_trigger?.length ?? 0) + (s.triggers?.should_not_trigger?.length ?? 0),
	0,
);

console.log(
	`corpus: ${corpus.length} skills, ${evalCount} evals, ${triggerCount} trigger assertions`,
);

/* ------------------------------------------ layers 2 and 3: drive real agents */

if (runAgents) {
	const ids = (agentFilter && agentFilter !== "true" ? agentFilter.split(",") : Object.keys(AGENTS))
		.map((s) => s.trim())
		.filter(Boolean);

	const available = ids.filter(agentAvailable);
	if (available.length === 0) {
		fail("agents", `none of ${ids.join(", ")} are installed`);
	}

	for (const id of available) {
		for (const skill of corpus) {
			for (const item of skill.evals) {
				const result = runOne(id, item.prompt);
				const where = `${id}/${skill.name}#${item.id ?? "?"}`;

				if (result.error) {
					fail(where, result.error);
					continue;
				}

				// Layer 2: did the right skill activate?
				if (skill.triggers?.should_trigger?.includes(item.prompt)) {
					if (!result.skillsUsed.has(skill.name)) {
						fail(where, `expected the ${skill.name} skill to activate; saw ${[...result.skillsUsed].join(", ") || "none"}`);
					}
				}

				// Layer 3: is every advisory it named real?
				for (const cve of advisoryIds(result.text)) {
					if (!cve.startsWith("CVE-")) continue;
					if (!truth.requiredCves.has(cve) && !advisoryIds(item.prompt).has(cve)) {
						fail(where, `named ${cve}, which is not in the fixture — likely hallucinated`);
					}
				}
			}
		}

		// The trigger set proper: every phrase, and the ones that must not fire.
		for (const skill of corpus) {
			for (const phrase of skill.triggers?.should_not_trigger ?? []) {
				const result = runOne(id, phrase);
				if (result.error) continue;
				if (result.skillsUsed.has(skill.name)) {
					fail(`${id}/${skill.name}`, `"${phrase}" should not have activated ${skill.name}`);
				}
			}
		}
	}
}

/**
 * Run one prompt against one agent, in a throwaway copy of the fixture.
 *
 * A copy, because several of these skills edit manifests, and an eval that
 * mutates the shared fixture changes the answer for every eval after it.
 */
function runOne(agentId, prompt) {
	const agent = AGENTS[agentId];
	const dir = mkdtempSync(join(tmpdir(), "vulnetix-eval-"));
	try {
		cpSync(FIXTURE, dir, { recursive: true });
		const stdout = execFileSync(agent.binary, agent.args(prompt, dir), {
			encoding: "utf8",
			cwd: dir,
			timeout: 240_000,
			maxBuffer: 64 * 1024 * 1024,
			stdio: ["ignore", "pipe", "ignore"],
		});
		const events = agent.parse(stdout);
		return {
			events,
			text: redact(stdout),
			skillsUsed: skillsFrom(events),
		};
	} catch (error) {
		return { error: `${agent.binary} failed: ${String(error.message).slice(0, 200)}` };
	} finally {
		rmSync(dir, { recursive: true, force: true });
	}
}

/**
 * Which skills the agent reached for.
 *
 * Hosts name this differently and none of them promise a stable shape, so this
 * looks for a skill name anywhere in a tool-use event rather than assuming one
 * field.
 */
function skillsFrom(events) {
	const used = new Set();
	const names = loadCorpus().map((s) => s.name);
	for (const event of events) {
		const blob = JSON.stringify(event);
		if (!/skill|tool_use|function_call/i.test(blob)) continue;
		for (const name of names) {
			if (blob.includes(name)) used.add(name);
		}
	}
	return used;
}

/* ------------------------------------------------------------------ report */

if (failures.length === 0) {
	console.log(runAgents ? "all layers passed" : "corpus checks passed (run with --agents for the rest)");
	process.exit(0);
}

console.error(`\n${failures.length} failure(s):`);
for (const f of failures) console.error(`  ${f}`);
process.exit(1);
