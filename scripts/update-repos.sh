#!/usr/bin/env bash
set -e

cd /workspaces

echo "🔄 Updating all Intellex repos..."

for repo in */ ; do
  if [ -d "$repo/.git" ]; then
    echo "⬇️ Pulling $repo..."
    cd "$repo"
    git pull --rebase
    cd ..
  fi
done

echo "✨ All repos updated."
