#!/usr/bin/env bash
# Install git hooks for automatic git-crypt unlock
# This script sets up hooks that automatically unlock git-crypt after git pull/checkout

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
HOOKS_DIR="$REPO_DIR/.git/hooks"

# Create hooks directory if it doesn't exist
mkdir -p "$HOOKS_DIR"

# Post-checkout hook (runs after checkout)
cat > "$HOOKS_DIR/post-checkout" << 'EOF'
#!/usr/bin/env bash
# Git post-checkout hook to automatically unlock git-crypt after checkout/pull
# This ensures encrypted files are decrypted after git operations

set -euo pipefail

# Only run if git-crypt is available and repository uses it
if command -v git-crypt >/dev/null 2>&1; then
  # Check if repository uses git-crypt
  if git-crypt status >/dev/null 2>&1; then
    # Try to unlock (will fail silently if already unlocked or no key available)
    # This is safe to run multiple times
    git-crypt unlock >/dev/null 2>&1 || true
  fi
fi
EOF

# Post-merge hook (runs after merge/pull)
cat > "$HOOKS_DIR/post-merge" << 'EOF'
#!/usr/bin/env bash
# Git post-merge hook to automatically unlock git-crypt after merge/pull
# This ensures encrypted files are decrypted after git pull operations

set -euo pipefail

# Only run if git-crypt is available and repository uses it
if command -v git-crypt >/dev/null 2>&1; then
  # Check if repository uses git-crypt
  if git-crypt status >/dev/null 2>&1; then
    # Try to unlock (will fail silently if already unlocked or no key available)
    # This is safe to run multiple times
    git-crypt unlock >/dev/null 2>&1 || true
  fi
fi
EOF

# Make hooks executable
chmod +x "$HOOKS_DIR/post-checkout"
chmod +x "$HOOKS_DIR/post-merge"

echo "✓ Git hooks installed successfully"
echo "  - post-checkout: Unlocks git-crypt after checkout"
echo "  - post-merge: Unlocks git-crypt after pull/merge"
