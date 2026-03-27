#!/usr/bin/env bash
set -euo pipefail

REPO_URL="https://github.com/neuvector/docs"
BRANCH="main"
REPO_DIR="source-repo"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
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

# --- Clone (skip if already exists) ---
if [ ! -d "$REPO_DIR" ]; then
  echo "Cloning $REPO_URL..."
  git clone --depth=1 --branch "$BRANCH" "$REPO_URL" "$REPO_DIR"
else
  echo "Using existing $REPO_DIR"
fi

cd "$REPO_DIR"

# --- Install Yarn v1 classic ---
echo "Installing yarn classic..."
npm install -g yarn@1

yarn --version

# --- Install dependencies ---
echo "Installing dependencies..."
yarn install --frozen-lockfile

# --- Apply fixes.json if present ---
FIXES_JSON="$SCRIPT_DIR/fixes.json"
if [ -f "$FIXES_JSON" ]; then
  echo "[INFO] Applying content fixes..."
  node -e "
  const fs = require('fs');
  const path = require('path');
  const fixes = JSON.parse(fs.readFileSync('$FIXES_JSON', 'utf8'));
  for (const [file, ops] of Object.entries(fixes.fixes || {})) {
    if (!fs.existsSync(file)) { console.log('  skip (not found):', file); continue; }
    let content = fs.readFileSync(file, 'utf8');
    for (const op of ops) {
      if (op.type === 'replace' && content.includes(op.find)) {
        content = content.split(op.find).join(op.replace || '');
        console.log('  fixed:', file, '-', op.comment || '');
      }
    }
    fs.writeFileSync(file, content);
  }
  for (const [file, cfg] of Object.entries(fixes.newFiles || {})) {
    const c = typeof cfg === 'string' ? cfg : cfg.content;
    fs.mkdirSync(path.dirname(file), {recursive: true});
    fs.writeFileSync(file, c);
    console.log('  created:', file);
  }
  "
fi

echo "[DONE] Repository is ready for docusaurus commands."
