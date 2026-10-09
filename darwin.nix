{ pkgs, self, ... }:

let
  # nixpkgs' 1.12.0 can't talk to Karabiner VirtualHIDDevice v8 (support landed
  # in 1.13). Drop this override once nixpkgs ships kanata >= 1.13.
  kanata = pkgs.kanata.overrideAttrs (old: rec {
    version = "1.13.0-prerelease-2";
    src = pkgs.fetchFromGitHub {
      owner = "jtroo";
      repo = "kanata";
      rev = "0d7f4e4d3995dc543e6ecd7e11d4b3802d9585ca";
      hash = "sha256-Mh8+GzN2Nu2SEKIynbt5b6BpL9fAxUaH4VGI1Da4CqY=";
    };
    cargoDeps = pkgs.rustPlatform.fetchCargoVendor {
      inherit src;
      name = "kanata-${version}";
      hash = "sha256-moRxx2X+mmJVtgopsTtN5s7jRyZ1Vz0F1qnFH/5SQZg=";
    };
  });
in
{
  # List packages installed in system profile. To search by name, run:
  # $ nix-env -qaP | grep wget
  environment.systemPackages =
    [ pkgs.vim
    ];

  # Necessary for using flakes on this system.
  nix.settings.experimental-features = "nix-command flakes";

  system.primaryUser = "alisher";
  users.users.alisher.home = "/Users/alisher";

  # Set Git commit hash for darwin-version.
  system.configurationRevision = self.rev or self.dirtyRev or null;

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 6;

  # The platform the configuration will be used on.
  nixpkgs.hostPlatform = "aarch64-darwin";

  programs.fish.enable = true;
  environment.shells = [ pkgs.fish ];

  # Runs as root from the read-only store, so the standard account can't swap
  # what root runs. Needs the Karabiner VirtualHIDDevice driver (from the
  # Karabiner-Elements install) and Input Monitoring permission for the binary,
  # which has to be granted again whenever the kanata store path changes.
  launchd.daemons.kanata.serviceConfig = {
    ProgramArguments = [
      "${kanata}/bin/kanata"
      "--nodelay"
      "-c"
      "${./config/kanata.kbd}"
    ];
    RunAtLoad = true;
    KeepAlive = true;
    ThrottleInterval = 5;
    StandardOutPath = "/Library/Logs/kanata.log";
    StandardErrorPath = "/Library/Logs/kanata.log";
  };

  homebrew = {
    enable = true;
    # Unlisted casks are left alone for now; switch to "uninstall" once the
    # list is complete.
    onActivation.cleanup = "none";

    taps = [ "d12frosted/emacs-plus" ];

    brews = [
      "mole" # nixpkgs' mole is a different program
      # Kept until emacs is migrated.
      "enchant"
      "hunspell"
      "tree-sitter"
    ];

    # brew runs as alisher (non-admin), so it can't run .pkg installers or add
    # apps to /Applications. Listed casks must already be installed/adopted;
    # .pkg-based apps (Karabiner-Elements, R, MacTeX, Adobe Digital Editions)
    # stay manual.
    casks = [
      # core
      "1password"
      "raycast"

      # browsers
      "helium-browser"

      # communication
      "discord"

      # work / study
      "figma"
      "zotero" # nixpkgs build is broken on darwin
      "emacs-plus-app@master"

      # utilities
      "gpg-suite"
    ];
  };
}
