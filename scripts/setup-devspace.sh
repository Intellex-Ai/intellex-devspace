#!/usr/bin/env bash
set -e

echo "🚀 Setting up Intellex Multi-Repo Codespace structure..."

# Create base dirs
mkdir -p .devcontainer
mkdir -p scripts
mkdir -p workspaces

###############################################
# 1. Create devcontainer.json
###############################################
cat > .devcontainer/devcontainer.json << 'EOF'
{
  "name": "Intellex Multi-Repo Devspace",
  "image": "mcr.microsoft.com/devcontainers/universal:2",
  "hostRequirements": {
    "cpus": 4,
    "memory": "8gb",
    "storage": "32gb"
  },

  "features": {
    "ghcr.io/devcontainers/features/node:1": {
      "version": "20",
      "pnpm": "latest"
    },
    "ghcr.io/devcontainers/features/python:1": {
      "version": "3.12"
    },
    "ghcr.io/devcontainers/features/github-cli:1": {}
  },

  "postCreateCommand": "bash scripts/setup.sh",

  "customizations": {
    "vscode": {
      "extensions": [
        "esbenp.prettier-vscode",
        "dbaeumer.vscode-eslint",
        "GitHub.copilot",
        "GitHub.copilot-chat",
        "GitHub.vscode-github-actions",
        "mhutchie.git-graph",
        "streetsidesoftware.code-spell-checker",
        "ms-python.python"
      ]
    }
  },

  "remoteUser": "codespace",
  "updateContentCommand": "bash scripts/update-repos.sh"
}
EOF

echo "✅ devcontainer.json created."


###############################################
# 2. Create setup.sh (auto clone + install)
###############################################
cat > scripts/setup.sh << 'EOF'
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
EOF

chmod +x scripts/setup.sh
echo "✅ scripts/setup.sh created."


###############################################
# 3. Create update-repos.sh
###############################################
cat > scripts/update-repos.sh << 'EOF'
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
EOF

chmod +x scripts/update-repos.sh
echo "✅ scripts/update-repos.sh created."


###############################################
# 4. Git safety script (optional)
###############################################
cat > scripts/setup-git-protection.sh << 'EOF'
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
EOF

chmod +x scripts/setup-git-protection.sh
echo "✅ scripts/setup-git-protection.sh created."


###############################################
# 5. VSCode Workspace File
###############################################
cat > intellex.code-workspace << 'EOF'
{
  "folders": [
    { "path": "workspaces/intellex-web" },
    { "path": "workspaces/intellex-api" },
    { "path": "workspaces/intellex-agents" },
    { "path": "workspaces/intellex-mcp" },
    { "path": "workspaces/intellex-shared" }
  ],
  "settings": {
    "files.exclude": {
      "**/node_modules": true
    },
    "editor.formatOnSave": true
  }
}
EOF

echo "✅ intellex.code-workspace created."


###############################################
# 6. README placeholder
###############################################
cat > README.md << 'EOF'
# Intellex Multi-Repo Devspace

This repository provides a single GitHub Codespace that manages **multiple Intellex repos** in one place.

This environment will automatically:

- Clone all Intellex repos into `/workspaces`
- Install dependencies
- Provide a unified VS Code environment
- Apply Git safety rules
- Support Codex + OpenAI workflows
EOF

echo "✅ README.md created."


###############################################
# 7. Devspace .gitignore
###############################################
cat > .gitignore << 'EOF'
# Prevent multi-repo checkouts from being committed
workspaces/

# Temp/system files
.DS_Store
node_modules/
dist/
.env
.env.*
EOF

echo "✅ .gitignore created."


echo ""
echo "🎉 Intellex Devspace structure fully generated!"
echo "👉 Add this repo to GitHub, open in Codespaces, and the magic happens."
