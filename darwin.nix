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
  environment.systemPackages = [
    pkgs.vim
    # Ghostty points TERMINFO into alisher's ~/Applications, which root
    # shells (sudo -i) don't see, so install xterm-ghostty system-wide.
    pkgs.ghostty-bin.terminfo
  ];

  nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (pkgs.lib.getName pkg) [ "slack" ];

  # Necessary for using flakes on this system.
  nix.settings.experimental-features = "nix-command flakes";

  # Weekly cleanup of the store.
  nix.gc = {
    automatic = true;
    interval = {
      Weekday = 0;
      Hour = 3;
      Minute = 0;
    };
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

  # Touch ID for sudo; reattach makes it work inside tmux too.
  security.pam.services.sudo_local = {
    touchIdAuth = true;
    reattach = true;
  };

  programs.fish.enable = true;
  environment.shells = [ pkgs.fish ];

  # kanata needs the Karabiner VirtualHIDDevice driver (from the
  # Karabiner-Elements install) plus Input Monitoring and Device Control and
  # Data Access; skhd (see home.nix) needs Device Control and Data Access;
  # restic needs Full Disk Access. macOS ties those permissions to the
  # binary's signature, and every store path is a new ad-hoc signature. So
  # activation copies each binary to a fixed root-owned path and signs it with
  # a local certificate (scripts/create-kanata-cert.sh); the permissions then
  # survive updates.
  system.activationScripts.extraActivation.text = ''
    # installSigned NAME STORE-BINARY RESTART-TARGET
    installSigned() {
      dir="/Library/Application Support/$1"
      if [ "$(cat "$dir/source" 2>/dev/null)" != "$2" ]; then
        echo "installing $1 from $2..." >&2
        install -d -o root -g wheel -m 755 "$dir"
        install -o root -g wheel -m 755 "$2" "$dir/$1.new"
        if /usr/bin/codesign --force --sign kanata-local --identifier "org.nixos.$1" \
            --keychain /Library/Keychains/System.keychain "$dir/$1.new"; then
          mv -f "$dir/$1.new" "$dir/$1"
          echo "$2" > "$dir/source"
          # The plist doesn't change on a binary-only update, so restart by hand.
          [ -z "$3" ] || launchctl kickstart -k "$3" 2>/dev/null || true
        else
          echo "warning: kanata-local signing identity missing; run scripts/create-kanata-cert.sh" >&2
          rm -f "$dir/$1.new"
        fi
      fi
    }
    installSigned kanata ${kanata}/bin/kanata system/org.nixos.kanata
    installSigned skhd ${pkgs.skhd}/bin/skhd \
      "gui/$(id -u alisher)/org.nix-community.home.skhd"
    # Full Disk Access for scheduled backups (see restic-b2 in home.nix).
    # The unwrapped binary: bin/restic only adds ssh/rclone to PATH, which S3 doesn't need.
    installSigned restic ${pkgs.restic}/bin/.restic-wrapped ""
  '';

  system.activationScripts.postActivation.text = pkgs.lib.mkAfter ''
    # nix-darwin only sets shells for users in knownUsers.
    fish=/run/current-system/sw/bin/fish
    if [ "$(dscl . -read /Users/alisher UserShell)" != "UserShell: $fish" ]; then
      echo "setting login shell to fish..." >&2
      dscl . -create /Users/alisher UserShell "$fish"
    fi

    # Restart the Dock again once Homebrew and home-manager have installed apps.
    killall -qu alisher Dock || true
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

  # Remote Login (sshd) off; nothing needs to SSH into this Mac.
  services.openssh.enable = false;

  # Block incoming connections to apps that haven't been allowed. Stealth mode
  # also ignores pings and probes to closed ports, so the Mac doesn't answer
  # scans on public networks. Outgoing traffic and replies are unaffected.
  networking.applicationFirewall = {
    enable = true;
    enableStealthMode = true;
    allowSigned = true; # Apple's own services (AirDrop, sharing)
    allowSignedApp = true; # downloaded apps with a valid Developer ID
  };

  # Written to alisher's preferences by the rebuild; the Dock may need a
  # logout to pick up changes.
  system.defaults = {
    dock = {
      orientation = "left";
      autohide = true;
      tilesize = 44;
      magnification = false;
      show-recents = false; # only the apps listed below
      wvous-br-corner = 1; # bottom-right hot corner: disabled
      persistent-apps = [
        "/Applications/Helium.app"
        "/Users/alisher/Applications/Home Manager Apps/Ghostty.app"
        "/Applications/Amgi.app"
      ];
    };

    trackpad.TrackpadThreeFingerVertSwipeGesture = 0; # no three-finger swipe up/down

    WindowManager.GloballyEnabled = false; # Stage Manager off
    spaces.spans-displays = false; # "Displays have separate Spaces", needed by rift

    # The folder is created by home.nix; macOS falls back to the Desktop
    # if it's missing.
    screencapture = {
      location = "/Users/alisher/Pictures/Screenshots";
      type = "png";
      disable-shadow = true;
    };

    NSGlobalDomain = {
      AppleMeasurementUnits = "Centimeters";
      AppleMetricUnits = 1;
      AppleTemperatureUnit = "Celsius";

      # Typing: fastest repeat the Settings sliders allow, and holding a key
      # repeats it (for vim) instead of opening the accent picker.
      KeyRepeat = 2;
      InitialKeyRepeat = 15;
      ApplePressAndHoldEnabled = false;

      # No autocorrect or "smart" rewriting; it mangles code and commands.
      NSAutomaticSpellingCorrectionEnabled = false;
      NSAutomaticCapitalizationEnabled = false;
      NSAutomaticPeriodSubstitutionEnabled = false; # double space -> ". "
      NSAutomaticQuoteSubstitutionEnabled = false;
      NSAutomaticDashSubstitutionEnabled = false;
      NSAutomaticInlinePredictionEnabled = false;

      AppleShowAllExtensions = true;
    };

    finder = {
      AppleShowAllExtensions = true;
      FXEnableExtensionChangeWarning = false;
      ShowPathbar = true;
      ShowStatusBar = true;
      FXDefaultSearchScope = "SCcf"; # search the current folder
      FXPreferredViewStyle = "Nlsv"; # list view
      _FXSortFoldersFirst = true;
      _FXShowPosixPathInTitle = true; # full path in the title bar
      NewWindowTarget = "Home"; # new windows open in ~
      FXRemoveOldTrashItems = true; # empty Trash items after 30 days
      QuitMenuItem = true; # allow ⌘Q on Finder
      CreateDesktop = false; # no icons on the desktop
      ShowExternalHardDrivesOnDesktop = false;
      ShowRemovableMediaOnDesktop = false;
    };

    CustomUserPreferences = {
      # AirDrop visible to contacts only, not everyone nearby.
      "com.apple.sharingd".DiscoverableMode = "Contacts Only";

      # No .DS_Store litter on network shares and USB drives.
      "com.apple.desktopservices" = {
        DSDontWriteNetworkStores = true;
        DSDontWriteUSBStores = true;
      };

      # Lock the Dock so it can only be changed here: no dragging apps on/off,
      # and the matching Dock controls in System Settings are greyed out.
      "com.apple.dock" = {
        contents-immutable = true;
        position-immutable = true;
        size-immutable = true;
        magnify-immutable = true;
        autohide-immutable = true;
      };
    };
  };

  environment.variables.HOMEBREW_NO_ANALYTICS = "1";

  homebrew = {
    enable = true;
    # Anything installed by brew but not listed here is removed with its data.
    onActivation.cleanup = "zap";
    # Show download and install progress.
    onActivation.extraFlags = [ "--verbose" ];

    taps = [
      "allenap/utils"
      "acsandmann/tap"
    ];

    brews = [
      "mole" # nixpkgs' mole is a different program
      "allenap/utils/rust-petname"
      "acsandmann/tap/rift" # tiling WM; not in nixpkgs, run by home.nix
      "ffmpeg"
      "sox"
      "mas" # installs masApps below
    ];

    casks = [
      # core
      {
        name = "bitwarden";
        args.appdir = "~/Applications";
      }
      "secretive" # SSH keys in the Secure Enclave; must live in /Applications
      "raycast"
      "karabiner-elements" # provides the virtual HID driver kanata needs

      # browsers
      "helium-browser"

      # communication
      "discord"

      # network / privacy
      "mullvad-vpn"
      "tor-browser"
      "lulu" # outbound firewall

      # tools
      "ollama-app"
      "claude-code"

      # work / study
      "figma"
      "zotero" # nixpkgs build is broken on darwin
    ];

    masApps = {
      WireGuard = 1451685025;
    };
  };
}
