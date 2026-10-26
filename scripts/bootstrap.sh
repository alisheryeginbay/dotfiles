#!/bin/bash
# Set up a fresh Mac from this repo:
#   bash -c "$(curl -fsSL https://raw.githubusercontent.com/alisheryeginbay/dotfiles/main/scripts/bootstrap.sh)"
# Safe to re-run: finished steps are skipped.
set -euo pipefail

REPO=https://github.com/alisheryeginbay/dotfiles.git
DIR=/private/etc/nix-darwin
HOST=MacBook-Pro
NIX=/nix/var/nix/profiles/default/bin/nix
FLAKES=(--extra-experimental-features "nix-command flakes")

step() { printf '\n\033[1;34m==> %s\033[0m\n' "$*"; }

# Ask for the password once and keep sudo alive until the script exits.
sudo -v
while true; do sudo -n true; sleep 50; kill -0 "$$" || exit; done 2>/dev/null &

if [ ! -x "$NIX" ]; then
  step "Installing Nix"
  curl -fsSL https://nixos.org/nix/install | sh -s -- --daemon --yes
fi

# Also installs the Xcode Command Line Tools.
if [ ! -x /opt/homebrew/bin/brew ]; then
  step "Installing Homebrew"
  NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# Git comes from nixpkgs, so this doesn't wait on Xcode tools.
if [ ! -d "$DIR/.git" ]; then
  step "Cloning $REPO into $DIR"
  sudo mkdir -p "$DIR"
  sudo chown "$USER:staff" "$DIR"
  "$NIX" "${FLAKES[@]}" run nixpkgs#git -- clone "$REPO" "$DIR"
fi

step "Applying the configuration (Homebrew installs take a while)"
if command -v darwin-rebuild >/dev/null; then
  sudo darwin-rebuild switch --flake "path:$DIR#$HOST"
else
  sudo "$NIX" "${FLAKES[@]}" run nix-darwin/master#darwin-rebuild -- \
    switch --flake "path:$DIR#$HOST"
fi

step "Done. Remaining manual steps:"
cat <<'EOF'
  - Open a new terminal (fish).
  - kanata certificate: sudo sh /private/etc/nix-darwin/scripts/create-kanata-cert.sh
  - Secretive: create a key, put it in gitSshKey in home.nix, add it to GitHub.
  - Grant permissions as macOS asks (Input Monitoring, Full Disk Access, LuLu).
EOF
