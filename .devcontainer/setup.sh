#!/usr/bin/env bash
set -e

echo "🔥 Intellex Devspace Setup Starting..."

mkdir -p /workspace/repos
cd /workspace/repos

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
