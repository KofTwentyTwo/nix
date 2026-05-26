#!/usr/bin/env bash
# Run local quality gates for the Nix configuration repository.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

RUN_DARWIN_BUILD=true

usage() {
  cat <<EOF
Usage: check-repo.sh [--quick]

Options:
  --quick   Skip the non-activating darwin-rebuild build
  -h        Show this help
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --quick)
      RUN_DARWIN_BUILD=false
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

section() {
  printf '\n==> %s\n' "$1"
}

fail_policy=0
policy_tmp="$(mktemp "${TMPDIR:-/tmp}/check-repo-policy.XXXXXX")"

cleanup() {
  rm -f "$policy_tmp"
}

trap cleanup EXIT

policy_error() {
  printf 'policy: %s\n' "$1" >&2
  fail_policy=1
}

section "repo policy"

if rg -n 'claude-skills-gsd|Load all four `~/.ai/`' home/codex home/gemini home/zsh >"$policy_tmp"; then
  cat "$policy_tmp" >&2
  policy_error "stale AI bootstrap or removed flake input reference found"
fi

if rg -n '"Bash\((rm|open|terragrunt apply|terragrunt taint|terragrunt run|python|python3|node):\*\)"' home/claude/default.nix >"$policy_tmp"; then
  cat "$policy_tmp" >&2
  policy_error "risky wildcard permission found in home/claude/default.nix"
fi

if [[ -f .claude/settings.local.json ]]; then
  risky_local_permissions="$(
    jq -r '
      .permissions.allow[]?
      | select(
          test("^Bash\\((rm|open|terragrunt apply|terragrunt taint|terragrunt run|python|python3|node):\\*\\)$")
          or test("^Bash\\((python|python3) -c")
          or test("^Bash\\(node -e")
          or test("^Bash\\((/bin/)?bash( |\\))")
          or test("^Bash\\(sh -c")
          or test("^Bash\\(curl -fsSL .*install\\.sh")
          or test("^Read\\(//var/folders")
        )
    ' .claude/settings.local.json
  )"
  if [[ -n "$risky_local_permissions" ]]; then
    printf '%s\n' "$risky_local_permissions" >&2
    policy_error "risky local Claude permissions found"
  fi
fi

pending_learnings=$(find learnings_to_process -maxdepth 1 -type f -name '*.md' | wc -l | tr -d ' ')
if [[ "$pending_learnings" -gt 0 ]]; then
  policy_error "pending learnings_to_process/*.md files must be promoted or rejected"
fi

if git ls-files --error-unmatch result >/dev/null 2>&1; then
  policy_error "result is a build artifact and must not be tracked"
fi

if [[ "$fail_policy" -ne 0 ]]; then
  exit 1
fi

section "shellcheck"
shellcheck scripts/*.sh home/wez/status-updater.sh home/1password/scripts/op-load-secrets.sh bootstrap.sh

section "markdownlint"
markdownlint-cli2 README.md AGENTS.md CLAUDE.md docs/*.md

section "nix flake check"
nix flake check --no-build --print-build-logs

if [[ "$RUN_DARWIN_BUILD" == true ]]; then
  section "darwin build"
  darwin-rebuild build --flake . --no-write-lock-file --print-build-logs
else
  section "darwin build skipped"
fi

section "ok"
