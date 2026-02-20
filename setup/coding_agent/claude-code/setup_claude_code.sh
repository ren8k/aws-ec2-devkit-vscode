#!/bin/bash

# ==============================================================================
# Claude Code setup script for EC2
# This script installs Node.js, Claude Code and adds configuration to ~/.profile
# ==============================================================================

set -e  # Exit on error

# ------------------------------------------------------------------------------
# Step 1: Install Node.js via nvm
# ------------------------------------------------------------------------------
echo "Installing Node.js via nvm..."

# Download and install nvm
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash

# Load nvm without restarting the shell
\. "$HOME/.nvm/nvm.sh"

# Install Node.js
nvm install 22

# Verify installation
echo "Verifying Node.js installation..."
node -v      # Should display "v22.x.x"
nvm current  # Should display "v22.x.x"
npm -v       # Should display npm version

# ------------------------------------------------------------------------------
# Step 2: Install Claude Code
# ------------------------------------------------------------------------------
echo
echo "Installing Claude Code..."

npm install -g @anthropic-ai/claude-code

if [ $? -eq 0 ]; then
    echo "Claude Code installed successfully"
else
    echo "Failed to install Claude Code"
    exit 1
fi

# ------------------------------------------------------------------------------
# Step 3: Add custom aliases to .bashrc
# ------------------------------------------------------------------------------
echo
echo "Adding custom aliases to .bashrc..."

cat >> "$HOME/.bashrc" << 'EOF'

# ========== custom ==========
alias ll='ls -la'

function cc() {
  claude --dangerously-skip-permissions "$@"
}
# ============================
EOF

echo "Custom aliases added to .bashrc"

echo
echo "Claude Code setup completed!"
echo "Run 'claude' to start using Claude Code"
echo
echo "Please customize CLAUDE.md, settings.json, and .claude.json!"
