#!/usr/bin/env bash
set -e

echo "🔐 Installing Git safety protections..."

HOOK=".git/hooks/pre-commit"

cat > $HOOK << 'EOT'
#!/usr/bin/env bash
ROOT_NAME="intellex-devspace"
CURRENT=$(basename "$(git rev-parse --show-toplevel)")

if [ "$CURRENT" = "$ROOT_NAME" ]; then
  echo "❌ Commit blocked: You are inside $ROOT_NAME."
  echo "👉 Commit inside: workspaces/<repo> instead."
  exit 1
fi
EOT

chmod +x $HOOK

echo "✔ Git protection hook installed."
