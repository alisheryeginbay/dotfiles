# nix-darwin

My macOS setup: [nix-darwin](https://github.com/nix-darwin/nix-darwin) for the
system and standalone [home-manager](https://github.com/nix-community/home-manager)
for my user, in one flake.

I use a standard (non-admin) account day to day, so the config is split along
that line:

| File | What | Applied by |
| --- | --- | --- |
| `home.nix` | CLI tools, fish, git, nvim, tmux, Ghostty, Emacs, fonts, some GUI apps | the standard user |
| `darwin.nix` | nix settings, Homebrew casks, kanata daemon | an admin |
| `config/` | raw config files linked in by the above | |

## Usage

```sh
# user config, no admin needed
home-manager switch --flake /etc/nix-darwin

# system config, from an admin account
sudo darwin-rebuild switch --flake path:/private/etc/nix-darwin#MacBook-Pro

# update everything
nix flake update
```

`path:` skips git's ownership check (the repo belongs to the standard user, the
rebuild runs as root), and `/private/etc` because `/etc` is a symlink.

## Notes

- **Apps:** GUI apps from nixpkgs land in `~/Applications/Home Manager Apps`.
  The rest are Homebrew casks; brew runs as the standard user, so casks must
  already be installed and `.pkg`-based apps stay manual.
- **Emacs:** Emacs and all its packages come from nixpkgs
  (`programs.emacs.extraPackages`). `config/emacs` is linked into
  `~/.config/emacs`, where state (caches, `secrets.el`, `custom.el`) stays local.
- **kanata:** runs as a root launchd daemon. Activation copies the binary to a
  fixed path and signs it with a local certificate, so the Input Monitoring
  permission survives updates. Create the certificate once with
  `sudo sh scripts/create-kanata-cert.sh`.
