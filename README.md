# nix-darwin

My macOS setup: [nix-darwin](https://github.com/nix-darwin/nix-darwin) for the
system and [home-manager](https://github.com/nix-community/home-manager) (as a
nix-darwin module) for my user, in one flake.

| File | What | Applied by |
| --- | --- | --- |
| `home.nix` | CLI tools, fish, git, nvim, tmux, Ghostty, fonts, some GUI apps | `darwin-rebuild` |
| `darwin.nix` | nix settings, macOS defaults, Homebrew casks, kanata daemon | `darwin-rebuild` |
| `config/` | raw config files linked in by the above | |

## New Mac

```sh
bash -c "$(curl -fsSL https://raw.githubusercontent.com/alisheryeginbay/dotfiles/main/scripts/bootstrap.sh)"
```

Installs Nix, Homebrew (with the Xcode Command Line Tools), clones this repo
and applies it. It prints the remaining manual steps at the end.

## Usage

```sh
# apply system and user config (sudo takes Touch ID)
nh darwin switch
# without nh (first install):
sudo darwin-rebuild switch --flake path:/private/etc/nix-darwin#MacBook-Pro

# update Nix packages (then rebuild) and Homebrew apps
nix flake update
brew upgrade
```

`path:` skips git's ownership check (the repo belongs to my user, the rebuild
runs as root), and `/private/etc` because `/etc` is a symlink.

## Notes

- **Apps:** GUI apps from nixpkgs land in `~/Applications/Home Manager Apps`.
  The rest are Homebrew casks.
- **kanata:** runs as a root launchd daemon. Activation copies the binary to a
  fixed path and signs it with a local certificate, so its permissions survive
  updates. One-time setup (log: `/Library/Logs/kanata.log`):
  1. Create the certificate: `sudo sh scripts/create-kanata-cert.sh`.
  2. Add `/Library/Application Support/kanata/kanata` under Privacy & Security →
     Input Monitoring and Device Control and Data Access.
  3. Activate the Karabiner driver:
     `/Applications/.Karabiner-VirtualHIDDevice-Manager.app/Contents/MacOS/Karabiner-VirtualHIDDevice-Manager activate`,
     then allow it in General → Login Items & Extensions → Driver Extensions.
  4. Restart: `sudo launchctl kickstart -k system/org.nixos.kanata`.
- **Helium:** flags aren't managed here. Set by hand:
  `helium://flags/#omnibox-autocomplete-filtering` → search suggestions only.
