#!/usr/bin/env node
/**
 * Record the terminal replays the marketing pages animate.
 *
 * Same harness as the evals: same commands, same fixture, same scenarios. That
 * is the whole point. The terminals on the feature pages used to be hand-written
 * markup carrying numbers nobody re-checked — "19,868 public exploits · last
 * seen 2 days ago" is a claim, not an observation. These frames come out of runs
 * that also have to pass their assertions, so the copy cannot drift from the
 * product without the recording changing too.
 *
 * Output is `AgentReplay[]` as defined in the website's
 * src/shared/coding-agents.ts, written per agent so the pages can import them.
 *
 * Usage:
 *   node scripts/record-demos.mjs                    # every agent found
 *   node scripts/record-demos.mjs --agents=claude
 *   node scripts/record-demos.mjs --out ../website/public/data/agent-replays
 */

import { execFileSync } from "node:child_process";
import { cpSync, mkdirSync, mkdtempSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";

import { AGENTS, FIXTURE, agentAvailable, redact } from "./eval-lib.mjs";

const argv = process.argv.slice(2);
const value = (name) => argv.find((a) => a.startsWith(`--${name}=`))?.split("=")[1];

const OUT = value("out") ?? join(import.meta.dirname, "..", "recordings");

/**
 * A faithful replay of a real run is mostly a forty-second pause, so gaps are
 * capped. The text is exactly what the agent emitted; the pacing is not, and the
 * pages say so.
 */
const MAX_GAP_MS = 1200;

/**
 * The scenarios, all grounded in the fixture's pinned contract: Log4Shell
 * (CVE-2021-44228, the one entry in requiredKev) plus four more across seven
 * ecosystems.
 */
const SCENARIOS = [
	{
		id: "dependency-guard",
		scenario: "Add axios for the HTTP client",
		caption:
			"The guard interrupts at the tool call, with the Safe Harbour verdict in the agent's own context.",
		prompt: "Add axios to package.json for the HTTP client.",
	},
	{
		id: "repo-impact",
		scenario: "Does Log4Shell affect us?",
		caption: "Answered from the dependency graph and the manifest line, not from the news.",
		prompt: "Does CVE-2021-44228 affect this repository? Be specific about where.",
	},
	{
		id: "fix",
		scenario: "Fix it",
		caption: "Proposes the manifest edit and refuses to run the package manager itself.",
		prompt: "Fix CVE-2021-44228 in this repository.",
	},
	{
		id: "dependency-choice",
		scenario: "I need JavaScript crypto",
		caption: "Weighs SubtleCrypto against crypto-js and crypto-es before adding anything.",
		prompt: "I need to do AES encryption in JavaScript. What should I use?",
	},
	{
		id: "change-guard",
		scenario: "Is this safe to commit?",
		caption: "A credential in the staged change stops the commit, with the reason the model can act on.",
		prompt: "Commit the current changes with the message 'add deploy script'.",
	},
];

/** Map a stream event onto a display line, or null to drop it. */
function toLine(event) {
	const type = event.type ?? event.event ?? "";

	// The user's own prompt, shown as the command that started it.
	if (type === "user" || event.role === "user") {
		const text = plain(event);
		return text ? { kind: "cmd", text: `> ${text}` } : null;
	}

	// A tool call — what the agent decided to do.
	if (/tool_use|function_call|exec/i.test(type) || event.tool_name || event.name) {
		const name = event.tool_name ?? event.name ?? "tool";
		const arg = plain(event).slice(0, 90);
		return { kind: "dim", text: `  ${name}${arg ? `  ${arg}` : ""}` };
	}

	const text = plain(event);
	if (!text) return null;

	// A refusal is the moment worth showing, so it gets the severity colour.
	if (/blocked|refus|deny|denied/i.test(text)) return { kind: "crit", text };
	if (/critical|malicious/i.test(text)) return { kind: "crit", text };
	if (/\bhigh\b|known exploited/i.test(text)) return { kind: "high", text };
	if (/no known vulnerabilities|clean|passed/i.test(text)) return { kind: "ok", text };

	return { kind: "text", text };
}

/** Pull whatever human-readable text an event carries, across host shapes. */
function plain(event) {
	const content = event.message?.content ?? event.content ?? event.text ?? event.delta;
	if (typeof content === "string") return redact(content).trim();
	if (Array.isArray(content)) {
		return redact(
			content
				.map((c) => (typeof c === "string" ? c : (c?.text ?? c?.input ? JSON.stringify(c.input) : "")))
				.filter(Boolean)
				.join(" "),
		).trim();
	}
	return "";
}

function record(agentId, scenario) {
	const agent = AGENTS[agentId];
	const dir = mkdtempSync(join(tmpdir(), "vulnetix-demo-"));
	const started = Date.now();

	try {
		cpSync(FIXTURE, dir, { recursive: true });

		const stdout = execFileSync(agent.binary, agent.args(scenario.prompt, dir), {
			encoding: "utf8",
			cwd: dir,
			timeout: 240_000,
			maxBuffer: 64 * 1024 * 1024,
			stdio: ["ignore", "pipe", "ignore"],
		});

		const lines = [];
		let last = started;

		for (const event of agent.parse(stdout)) {
			const line = toLine(event);
			if (!line) continue;

			// Wall-clock is not available per event on every host, so the gap is
			// derived from arrival order and then capped. Honest about pacing:
			// the frames are real, the timing is a rendering choice.
			const now = Date.now();
			line.delay = Math.min(Math.max(now - last, 80), MAX_GAP_MS);
			last = now;

			// Collapse the runs of identical lines a streaming host emits.
			if (lines.at(-1)?.text === line.text) continue;
			lines.push(line);
		}

		return { scenario: scenario.scenario, caption: scenario.caption, lines };
	} catch (error) {
		console.error(`  ${scenario.id}: ${String(error.message).slice(0, 160)}`);
		return null;
	} finally {
		rmSync(dir, { recursive: true, force: true });
	}
}

const requested = value("agents")?.split(",").map((s) => s.trim()) ?? Object.keys(AGENTS);
const available = requested.filter(agentAvailable);

if (available.length === 0) {
	console.error(`None of ${requested.join(", ")} are installed.`);
	process.exit(1);
}

mkdirSync(OUT, { recursive: true });

for (const agentId of available) {
	console.log(`recording ${agentId}`);
	const replays = [];
	for (const scenario of SCENARIOS) {
		const replay = record(agentId, scenario);
		if (replay?.lines.length) replays.push(replay);
	}

	const path = join(OUT, `${agentId}.json`);
	writeFileSync(path, `${JSON.stringify(replays, null, "\t")}\n`);
	console.log(`  ${replays.length}/${SCENARIOS.length} scenarios -> ${path}`);
}
