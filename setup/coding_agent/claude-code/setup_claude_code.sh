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
# Step 3: Configure Claude Code for AWS Bedrock
# ------------------------------------------------------------------------------
echo
echo "Setting up Claude Code configuration..."

# Check if the configuration already exists
if grep -q "# Claude Code settings" ~/.profile 2>/dev/null; then
    echo "Claude Code settings already exist in ~/.profile"
    echo "Skipping configuration..."
else
    # Append Claude Code settings to ~/.profile
    cat >> ~/.profile << 'EOF'

# Claude Code settings
export CLAUDE_CODE_USE_BEDROCK=1
export ANTHROPIC_MODEL="us.anthropic.claude-opus-4-20250514-v1:0"
# export ANTHROPIC_MODEL="us.anthropic.claude-sonnet-4-20250514-v1:0"
export AWS_REGION="us-west-2"
# export AWS_PROFILE="your-profile"  # Uncomment if using specific AWS profile
EOF

    echo "Claude Code settings added to ~/.profile"
fi

# ------------------------------------------------------------------------------
# Step 4: Apply configuration
# ------------------------------------------------------------------------------
echo
echo "Applying configuration..."
source ~/.profile

echo
echo "Claude Code setup completed!"
echo "Run 'claude' to start using Claude Code"
