#!/usr/bin/env bash
set -e

echo "🔥 Intellex Devspace Setup Starting..."

# Set up GitHub SSH authentication
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
bash "$SCRIPT_DIR/setup-github-ssh.sh" || true

mkdir -p /workspaces/intellex-devspace/repos
cd /workspaces/intellex-devspace/repos

REPOS=(
  "https://github.com/Intellex-Ai/intellex-web.git"
  "https://github.com/Intellex-Ai/intellex-api.git"
)

for REPO in "${REPOS[@]}"; do
  NAME=$(basename "$REPO" .git)
  if [ ! -d "$NAME" ]; then
    echo "📥 Cloning $NAME ..."
    git clone "$REPO"
  else
    echo "✔ $NAME already exists, skipping"
  fi
done

echo "✨ All Intellex repos are ready!"
