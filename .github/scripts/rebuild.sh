#!/usr/bin/env bash
set -euo pipefail

# Rebuild script for neuvector/docs
# Runs on existing source tree (no clone). Installs deps and builds.
# Docusaurus 3.3.2, Node 20, Yarn v1 (classic)

NODE_VERSION="20"

# --- Node.js via nvm ---
export NVM_DIR="${HOME}/.nvm"
if [ ! -f "$NVM_DIR/nvm.sh" ]; then
  echo "Installing nvm..."
  curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
fi
# shellcheck source=/dev/null
source "$NVM_DIR/nvm.sh"

echo "Installing Node $NODE_VERSION..."
nvm install "$NODE_VERSION"
nvm use "$NODE_VERSION"

node --version
npm --version

# --- Install Yarn v1 classic ---
echo "Installing yarn classic..."
npm install -g yarn@1

yarn --version

# --- Install dependencies ---
echo "Installing dependencies..."
yarn install --frozen-lockfile

# --- Build ---
echo "Running build..."
yarn build

echo "[DONE] Build complete."
