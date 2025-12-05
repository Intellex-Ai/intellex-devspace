#!/usr/bin/env bash
set -e

echo "🔑 Setting up GitHub SSH authentication..."

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

# Start SSH agent and add key
echo "🚀 Starting SSH agent..."
eval "$(ssh-agent -s)" > /dev/null

# Add key to SSH agent if not already added
if ! ssh-add -l | grep -q "$SSH_KEY_PATH"; then
  ssh-add "$SSH_KEY_PATH"
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
if ssh -T git@github.com 2>&1 | grep -q "successfully authenticated"; then
  echo "✅ GitHub SSH authentication successful!"
else
  echo "⚠️  GitHub SSH authentication pending - add the public key above to your GitHub account"
fi

