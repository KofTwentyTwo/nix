/**
 * safe-bash: pause for confirmation before destructive shell commands.
 *
 * Intercepts the `bash` tool via the `tool_call` event. If the command
 * matches a known-dangerous pattern, prompts the user before allowing
 * execution. In non-interactive mode (no UI), blocks by default — the
 * agent cannot proceed without explicit human approval.
 *
 * Patterns gated:
 *   - rm -rf / -fr / --recursive
 *   - sudo
 *   - chmod / chown 777
 *   - terraform apply | destroy
 *   - kubectl delete
 *   - aws s3 rm | mv
 *   - aws s3 sync --delete
 *   - helm uninstall
 *   - git push --force | -f
 *
 * Modeled on pi's bundled permission-gate.ts example. Maps to the
 * ~/.ai/3-rules.md "Pause on failure / destructive commands" mandate.
 */

import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

interface DangerousPattern {
	pattern: RegExp;
	label: string;
}

const DANGEROUS_PATTERNS: DangerousPattern[] = [
	{ pattern: /\brm\s+(-rf?|-fr|--recursive)/i, label: "rm -rf" },
	{ pattern: /\bsudo\b/i, label: "sudo" },
	{ pattern: /\b(chmod|chown)\b.*\b777\b/i, label: "777 perms" },
	{ pattern: /\bterraform\s+(apply|destroy)\b/i, label: "terraform apply/destroy" },
	{ pattern: /\bkubectl\s+delete\b/i, label: "kubectl delete" },
	{ pattern: /\baws\s+s3\s+(rm|mv)\b/i, label: "aws s3 rm/mv" },
	{ pattern: /\baws\s+s3\s+sync\b.*--delete/i, label: "aws s3 sync --delete" },
	{ pattern: /\bhelm\s+uninstall\b/i, label: "helm uninstall" },
	{ pattern: /\bgit\s+push\s+(--force|-f)/i, label: "git push --force" },
];

export default function (pi: ExtensionAPI) {
	pi.on("tool_call", async (event, ctx) => {
		if (event.toolName !== "bash") return undefined;

		const command = (event.input.command as string) ?? "";
		const matches = DANGEROUS_PATTERNS.filter((p) => p.pattern.test(command));

		if (matches.length === 0) return undefined;

		const label = matches.map((m) => m.label).join(", ");

		if (!ctx.hasUI) {
			return { block: true, reason: `safe-bash: blocked dangerous command (${label}) — no UI for confirmation` };
		}

		// "No, cancel" first so accidental Enter defaults to safe.
		const choice = await ctx.ui.select(
			`⚠️  Destructive command (${label}):\n\n  ${command}\n\nAllow?`,
			["No, cancel", "Yes, proceed"],
		);

		if (choice !== "Yes, proceed") {
			return { block: true, reason: `safe-bash: blocked by user (${label})` };
		}

		return undefined;
	});
}
