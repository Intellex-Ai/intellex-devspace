#!/usr/bin/env bash
set -e

echo "🌐 Setting up Intellex multi-repo workspace..."

mkdir -p /workspaces
cd /workspaces

REPOS=(
  "intellex-web"
  "intellex-api"
  "intellex-agents"
  "intellex-mcp"
  "intellex-shared"
)

GITHUB_ORG="Intellex-Ai"

for repo in "${REPOS[@]}"; do
  if [ ! -d "$repo" ]; then
    echo "📥 Cloning $repo..."
    git clone "https://github.com/$GITHUB_ORG/$repo.git"
  else
    echo "✔ $repo already exists — skipping"
  fi
done

echo "📦 Installing dependencies for each Node repo..."
for repo in "${REPOS[@]}"; do
  if [ -f "$repo/package.json" ]; then
    echo "📦 Installing deps for $repo..."
    cd "$repo"
    pnpm install || true
    cd ..
  fi
done

echo "✨ Intellex setup complete!"
