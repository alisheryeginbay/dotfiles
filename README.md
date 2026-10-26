# nix-darwin

My macOS setup: [nix-darwin](https://github.com/nix-darwin/nix-darwin) for the
system and standalone [home-manager](https://github.com/nix-community/home-manager)
for my user, in one flake.

| File | What | Applied by |
| --- | --- | --- |
| `home.nix` | CLI tools, fish, git, nvim, tmux, Ghostty, Emacs, fonts, some GUI apps | `home-manager`, no sudo |
| `darwin.nix` | nix settings, macOS defaults, Homebrew casks, kanata daemon | `darwin-rebuild`, with sudo |
| `config/` | raw config files linked in by the above | |

## Usage

```sh
# user config
home-manager switch --flake /etc/nix-darwin

# system config (sudo takes Touch ID)
sudo darwin-rebuild switch --flake path:/private/etc/nix-darwin#MacBook-Pro

# update everything
nix flake update
```

`path:` skips git's ownership check (the repo belongs to my user, the rebuild
runs as root), and `/private/etc` because `/etc` is a symlink.

## Notes

- **Apps:** GUI apps from nixpkgs land in `~/Applications/Home Manager Apps`.
  The rest are Homebrew casks.
- **Emacs:** Emacs and all its packages come from nixpkgs
  (`programs.emacs.extraPackages`). `config/emacs` is linked into
  `~/.config/emacs`, where state (caches, `secrets.el`, `custom.el`) stays local.
- **kanata:** runs as a root launchd daemon. Activation copies the binary to a
  fixed path and signs it with a local certificate, so the Input Monitoring
  permission survives updates. Create the certificate once with
  `sudo sh scripts/create-kanata-cert.sh`.
