{ pkgs, self, ... }:

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

    casks = [
      # core
      "1password"
      "raycast"
      "ghostty"
      "karabiner-elements" # provides the driver kanata needs

      # browsers
      "helium-browser"

      # communication
      "slack"
      "discord"

      # work / study
      "figma"
      "zotero"
      "anki"
      "calibre"
      "adobe-digital-editions"
      "r-app"
      "mactex"
      "emacs-plus-app@master"

      # utilities
      "balenaetcher"
      "gpg-suite"

      # fonts
      "font-aporetic"
    ];
  };
}
