#!/usr/bin/env bash
set -e

echo "🔑 Setting up GitHub SSH authentication..."

# Detect environment
if [ -n "$CODESPACES" ] || [ -n "$GITHUB_CODESPACE_TOKEN" ]; then
  echo "📍 Detected GitHub Codespaces environment"
  IN_CODESPACES=true
else
  echo "📍 Detected local devcontainer environment"
  IN_CODESPACES=false
fi

# Ensure .ssh directory exists
mkdir -p ~/.ssh
chmod 700 ~/.ssh

# Generate SSH key if it doesn't exist
SSH_KEY_PATH=~/.ssh/id_ed25519
if [ ! -f "$SSH_KEY_PATH" ]; then
  echo "📝 Generating new SSH key..."
  ssh-keygen -t ed25519 -C "devcontainer@intellex" -f "$SSH_KEY_PATH" -N ""
  echo "✅ SSH key generated at $SSH_KEY_PATH"
else
  echo "✔ SSH key already exists at $SSH_KEY_PATH"
fi

# Start SSH agent and add key (only needed for local devcontainers)
if [ "$IN_CODESPACES" = false ]; then
  echo "🚀 Starting SSH agent..."
  # Check if agent is already running
  if [ -z "$SSH_AUTH_SOCK" ]; then
    eval "$(ssh-agent -s)" > /dev/null
    # Add to shell profile so it persists (only if not already added)
    if ! grep -q "ssh-agent" ~/.bashrc 2>/dev/null; then
      echo '' >> ~/.bashrc
      echo '# Auto-start SSH agent for GitHub' >> ~/.bashrc
      echo 'eval "$(ssh-agent -s)" > /dev/null' >> ~/.bashrc
      echo 'ssh-add ~/.ssh/id_ed25519 2>/dev/null' >> ~/.bashrc
    fi
  fi
else
  echo "✔ Codespaces handles SSH agent automatically"
fi

# Add key to SSH agent if not already added
if ! ssh-add -l 2>/dev/null | grep -q "$SSH_KEY_PATH"; then
  ssh-add "$SSH_KEY_PATH" 2>/dev/null
  echo "✅ SSH key added to agent"
else
  echo "✔ SSH key already in agent"
fi

# Configure SSH to use the key for GitHub
SSH_CONFIG=~/.ssh/config
if [ ! -f "$SSH_CONFIG" ] || ! grep -q "Host github.com" "$SSH_CONFIG"; then
  echo "⚙️  Configuring SSH for GitHub..."
  cat >> "$SSH_CONFIG" << EOF

Host github.com
  HostName github.com
  User git
  IdentityFile $SSH_KEY_PATH
  StrictHostKeyChecking no
EOF
  chmod 600 "$SSH_CONFIG"
  echo "✅ SSH config updated"
else
  echo "✔ SSH config already configured for GitHub"
fi

# Configure git to use SSH with the key directly (works for GUI too)
# Skip this in Codespaces - it already handles SSH automatically
if [ -z "$CODESPACES" ] && [ -z "$GITHUB_CODESPACE_TOKEN" ]; then
  echo "⚙️  Configuring git to use SSH key (local devcontainer only)..."
  # Use absolute path for SSH key to ensure it works in all contexts
  SSH_KEY_ABS=$(readlink -f "$SSH_KEY_PATH" || echo "$SSH_KEY_PATH")
  SSH_CONFIG_ABS=$(readlink -f "$SSH_CONFIG" || echo "$SSH_CONFIG")
  git config --global core.sshCommand "ssh -i '$SSH_KEY_ABS' -F '$SSH_CONFIG_ABS'"
  echo "✅ Git SSH command configured (works for GUI and CLI)"
else
  echo "✔ Running in Codespaces - git SSH is already configured automatically"
fi

# Display public key
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📋 Your public SSH key (add this to GitHub):"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
cat "$SSH_KEY_PATH.pub"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📝 To add this key to GitHub:"
echo "   1. Copy the public key above"
echo "   2. Go to https://github.com/settings/keys"
echo "   3. Click 'New SSH key'"
echo "   4. Paste the key and save"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Test connection (will fail until key is added to GitHub, but shows the setup is working)
echo "🧪 Testing GitHub SSH connection..."
# Ensure agent is running for the test (only for local devcontainers)
if [ "$IN_CODESPACES" = false ] && [ -z "$SSH_AUTH_SOCK" ]; then
  eval "$(ssh-agent -s)" > /dev/null
  ssh-add "$SSH_KEY_PATH" 2>/dev/null
fi

if ssh -T git@github.com 2>&1 | grep -q "successfully authenticated\|Hi "; then
  echo "✅ GitHub SSH authentication successful!"
else
  if [ "$IN_CODESPACES" = true ]; then
    echo "⚠️  In Codespaces, git operations use automatic authentication"
    echo "   If you need SSH access, add the public key above to your GitHub account"
  else
    echo "⚠️  GitHub SSH authentication pending - add the public key above to your GitHub account"
  fi
  echo "   Public key: $(cat "$SSH_KEY_PATH.pub")"
fi

