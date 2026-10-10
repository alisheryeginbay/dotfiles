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
      # Ghostty points TERMINFO into alisher's private ~/Applications, so other
      # users (e.g. after `su`) need xterm-ghostty installed system-wide.
      pkgs.ghostty-bin.terminfo
    ];

  # Necessary for using flakes on this system.
  nix.settings.experimental-features = "nix-command flakes";

  # Weekly cleanup of the store. Old home-manager generations are expired by
  # nix.gc in home.nix (they're the user's GC roots, so root can't drop them).
  nix.gc = {
    automatic = true;
    interval = { Weekday = 0; Hour = 3; Minute = 0; };
    options = "--delete-older-than 30d";
  };
  nix.optimise.automatic = true;

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

  # kanata needs the Karabiner VirtualHIDDevice driver (from the
  # Karabiner-Elements install) and Input Monitoring permission. macOS ties
  # that permission to the binary's signature, and every store path is a new
  # ad-hoc signature. So activation copies kanata to a fixed root-owned path
  # and signs it with a local certificate (scripts/create-kanata-cert.sh);
  # the permission then survives kanata updates.
  system.activationScripts.extraActivation.text = ''
    kanataDir="/Library/Application Support/kanata"
    if [ "$(cat "$kanataDir/source" 2>/dev/null)" != "${kanata}" ]; then
      echo "installing kanata from ${kanata}..." >&2
      install -d -o root -g wheel -m 755 "$kanataDir"
      install -o root -g wheel -m 755 ${kanata}/bin/kanata "$kanataDir/kanata.new"
      if /usr/bin/codesign --force --sign kanata-local --identifier org.nixos.kanata \
          --keychain /Library/Keychains/System.keychain "$kanataDir/kanata.new"; then
        mv -f "$kanataDir/kanata.new" "$kanataDir/kanata"
        echo "${kanata}" > "$kanataDir/source"
        # The plist doesn't change on a binary-only update, so restart by hand.
        launchctl kickstart -k system/org.nixos.kanata 2>/dev/null || true
      else
        echo "warning: kanata-local signing identity missing; run scripts/create-kanata-cert.sh" >&2
        rm -f "$kanataDir/kanata.new"
      fi
    fi
  '';

  launchd.daemons.kanata.serviceConfig = {
    ProgramArguments = [
      "/Library/Application Support/kanata/kanata"
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

  # Written to alisher's preferences by the admin rebuild; the Dock may need a
  # logout to pick up changes.
  system.defaults = {
    dock = {
      orientation = "left";
      autohide = true;
      tilesize = 44;
      magnification = false;
      wvous-br-corner = 1; # bottom-right hot corner: disabled
      persistent-apps = [
        "/Applications/Helium.app"
        "/Users/alisher/Applications/Home Manager Apps/Ghostty.app"
        "/Users/alisher/Applications/Home Manager Apps/Emacs.app"
        "/Users/alisher/Applications/Home Manager Apps/Anki.app"
      ];
    };

    WindowManager.GloballyEnabled = false; # Stage Manager off

    NSGlobalDomain = {
      AppleMeasurementUnits = "Centimeters";
      AppleMetricUnits = 1;
      AppleTemperatureUnit = "Celsius";
    };

    # Thinner text in Emacs (the daemon runs inside Emacs.app for this).
    CustomUserPreferences."org.gnu.Emacs".AppleFontSmoothing = 0;
  };

  homebrew = {
    enable = true;
    # Unlisted casks are left alone for now; switch to "uninstall" once the
    # list is complete.
    onActivation.cleanup = "none";

    brews = [
      "mole" # nixpkgs' mole is a different program
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
    ];
  };
}
