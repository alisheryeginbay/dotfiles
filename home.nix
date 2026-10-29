{
  config,
  lib,
  pkgs,
  ...
}:

let
  # Public half of the Secretive (Secure Enclave) key: GitHub auth and commit
  # signing.
  gitSshKey = "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBITgs3/7KEeyKAV5h2+K7zoMMIGKIDzpLTY/hEjLEjIQUTnDtZG8jlDMbDKCEK62rkvl1omdQWoTMjdypg0Znrw=";
  # Signed commits before 2026-10-26; kept so they still verify.
  oldGitSshKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIENGgSzne1Wl2M5z+pOPcTTi9ebGdP03JwO4JUbiYTO3";
  secretiveAgent = "$HOME/Library/Containers/com.maxgoedjen.Secretive.SecretAgent/Data/socket.ssh";
  gitEmail = "alisher@yeginbay.com";
  # restic against B2; repo URL and secrets come from the login keychain
  # (service restic-b2). Execs the signed copy so Full Disk Access applies.
  resticB2 = pkgs.writeShellScriptBin "restic-b2" ''
    kc() { /usr/bin/security find-generic-password -s restic-b2 -a "$1" -w; }
    export RESTIC_REPOSITORY="$(kc repo)"
    export AWS_ACCESS_KEY_ID="$(kc key-id)"
    export AWS_SECRET_ACCESS_KEY="$(kc key)"
    export RESTIC_PASSWORD_COMMAND="/usr/bin/security find-generic-password -s restic-b2 -a password -w"
    exec "/Library/Application Support/restic/restic" "$@"
  '';
  logPath = name: "${config.home.homeDirectory}/Library/Logs/${name}.log";
  # Runs a shell command; on failure, posts a macOS notification pointing at the log.
  notifyOnFailure =
    name: cmd:
    pkgs.writeShellScript name ''
      {
        ${cmd}
      } || {
        status=$?
        /usr/bin/osascript -e "display notification \"Exit $status. See ~/Library/Logs/${name}.log\" with title \"${name} failed\""
        exit $status
      }
    '';
in
{
  home.username = "alisher";
  home.homeDirectory = "/Users/alisher";
  home.stateVersion = "25.11";

  home.packages = with pkgs; [
    # shell utilities
    neovim
    sesh # tmux session manager; picker on prefix+s (config/tmux.conf)
    bat
    eza
    ripgrep
    fastfetch
    macism

    # dev
    bun
    fnm
    uv
    rustup
    ruff
    ty
    shfmt
    lua-language-server
    nixd # Nix LSP (nvim lsp.lua)
    nixfmt # Nix formatter, run by nixd on save
    stylua # Lua formatter (.stylua.toml), runs as an LSP on save
    markdown-oxide # markdown notes LSP (nvim lsp.lua)
    tree-sitter # nvim-treesitter (main) builds parsers with it
    luarocks
    oxfmt
    git-xet

    # documents / media
    pandoc
    hugo
    imagemagick
    exiftool
    poppler-utils
    djvulibre
    mpv

    # Typst: compiler, language server and formatter.
    typst
    tinymist
    typstyle

    # R plus the "recommended" packages the official installer bundles.
    # Add CRAN packages to the list (install.packages() won't persist).
    (rWrapper.override {
      packages = with rPackages; [
        boot
        class
        cluster
        codetools
        foreign
        KernSmooth
        lattice
        MASS
        Matrix
        mgcv
        nlme
        nnet
        rpart
        spatial
        survival
        ggplot2
      ];
    })

    # apps (copied to ~/Applications/Home Manager Apps)
    anki-bin
    slack
    # fonts
    aporetic

    # misc
    restic
    resticB2
    rage
    (buildGoModule rec {
      pname = "tle";
      version = "1.2.0";
      src = fetchFromGitHub {
        owner = "drand";
        repo = "tlock";
        rev = "v${version}";
        hash = "sha256-3qO5xGcKj7m033B/lWoeewUf9XbiY+GrQFBBuymOXzo=";
      };
      vendorHash = "sha256-gy2aPcOrhN1M27qYiqRvNjy987Oh7/MHMvbRLEpV3Iw=";
      subPackages = [ "cmd/tle" ];
      meta.mainProgram = "tle";
    })
  ];

  programs.fish = {
    enable = true;
    shellInit = ''
      set -g fish_greeting
      set -gx EDITOR nvim
      set -gx BUN_INSTALL $HOME/.bun
      # Set every time so tmux panes can't keep a stale agent path.
      set -gx SSH_AUTH_SOCK ${secretiveAgent}
    '';
    interactiveShellInit = ''
      fnm env --use-on-cd --shell fish | source
    '';
    shellAliases = {
      ls = "eza --all --long --group --group-directories-first --icons --header --time-style long-iso";
      grt = ''cd "$(git rev-parse --show-toplevel)"'';
      cat = "bat";
    };
  };

  # `nh darwin switch` rebuilds this flake; path: includes untracked files.
  programs.nh = {
    enable = true;
    flake = "path:/private/etc/nix-darwin";
  };

  home.sessionPath = [
    "$HOME/.bun/bin"
    "$HOME/.cargo/bin"
    "$HOME/.local/bin"
  ];
  # Appended to $PATH itself so Nix-provided tools take precedence over Homebrew's.
  programs.fish.loginShellInit = ''
    fish_add_path --path --append /opt/homebrew/bin
  '';

  programs.fzf.enable = true;
  programs.starship.enable = true;
  programs.zoxide = {
    enable = true;
    options = [
      "--cmd"
      "cd"
    ];
  };

  programs.git = {
    enable = true;
    lfs.enable = true;
    ignores = [
      "**/.claude/.cc-writes/"
      "**/.claude/settings.local.json"
    ];
    signing = {
      format = "ssh";
      key = "key::${gitSshKey}";
      signByDefault = true;
    };
    settings = {
      user.name = "Alisher Yeginbay";
      user.email = gitEmail;
      # Lets `git log --show-signature` verify my own commits.
      gpg.ssh.allowedSignersFile = "${pkgs.writeText "allowed_signers" ''
        ${gitEmail} ${gitSshKey}
        ${gitEmail} ${oldGitSshKey}
      ''}";
      init.defaultBranch = "main";
      lfs.concurrenttransfers = 3;
      "lfs \"customtransfer.xet\"" = {
        path = "git-xet";
        args = "transfer";
        concurrent = true;
      };
    };
  };

  # Pager for git diffs; picks light/dark colors from the terminal.
  programs.delta = {
    enable = true;
    enableGitIntegration = true;
    options = {
      navigate = true; # n/N jump between files
      line-numbers = true;
    };
  };

  # SSH keys live in the Secure Enclave via Secretive, which serves them
  # through its agent.
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    # No IdentityFile: ssh offers the keys the agent holds.
    settings."*".IdentityAgent =
      "~/Library/Containers/com.maxgoedjen.Secretive.SecretAgent/Data/socket.ssh";
  };

  programs.gh = {
    enable = true;
    settings = {
      git_protocol = "https";
      aliases.co = "pr checkout";
    };
  };

  programs.ghostty = {
    enable = true;
    package = pkgs.ghostty-bin;
    settings = {
      shell-integration = "fish";
      shell-integration-features = "sudo,ssh-env";
      font-family = "Aporetic Sans Mono";
      font-size = 16;
      keybind = [ "shift+enter=text:\\n" ];
      window-save-state = "always";
      macos-option-as-alt = true;
      theme = "dark:Modus Vivendi,light:Modus Operandi";
    };
  };

  # Out-of-store symlink so lazy.nvim can still write lazy-lock.json.
  xdg.configFile."nvim".source = config.lib.file.mkOutOfStoreSymlink "/etc/nix-darwin/config/nvim";

  programs.tmux = {
    enable = true;
    prefix = "C-a";
    baseIndex = 1;
    mouse = false;
    terminal = "tmux-256color";
    escapeTime = 0;
    focusEvents = true;
    historyLimit = 50000;
    plugins = with pkgs.tmuxPlugins; [
      sensible
      resurrect
      continuum # auto-saves via resurrect; restore is off
      yank
      vim-tmux-navigator
    ];
  };
  # Placed before the plugins (which home-manager loads at order 1000):
  # continuum hooks its auto-save into status-right, so status-right has to
  # be set before it loads or the hook gets overwritten.
  xdg.configFile."tmux/tmux.conf".text = lib.mkOrder 600 (builtins.readFile ./config/tmux.conf);

  # Out-of-store so preset edits apply without a rebuild.
  xdg.configFile."sesh/sesh.toml".source =
    config.lib.file.mkOutOfStoreSymlink "/etc/nix-darwin/config/sesh.toml";

  # Daily at noon; launchd runs a missed job on wake.
  launchd.agents.restic-backup = {
    enable = true;
    config = {
      ProgramArguments = [
        "${notifyOnFailure "restic-backup" ''
          ${lib.getExe resticB2} backup --retry-lock 30m --exclude-caches \
            "$HOME/Documents" \
            "$HOME/flashcards" \
            "$HOME/.local/share/plock"
        ''}"
      ];
      StartCalendarInterval = [
        {
          Hour = 12;
          Minute = 0;
        }
      ];
      LowPriorityIO = true;
      ProcessType = "Background";
      StandardOutPath = logPath "restic-backup";
      StandardErrorPath = logPath "restic-backup";
    };
  };

  # Weekly: drop old snapshots, then verify the repo.
  launchd.agents.restic-prune = {
    enable = true;
    config = {
      ProgramArguments = [
        "${notifyOnFailure "restic-prune" ''
          ${lib.getExe resticB2} forget --retry-lock 30m --prune \
            --keep-daily 7 --keep-weekly 4 --keep-monthly 12 &&
          ${lib.getExe resticB2} check
        ''}"
      ];
      StartCalendarInterval = [
        {
          Weekday = 0;
          Hour = 13;
          Minute = 0;
        }
      ];
      LowPriorityIO = true;
      ProcessType = "Background";
      StandardOutPath = logPath "restic-prune";
      StandardErrorPath = logPath "restic-prune";
    };
  };

  # Language keys: kanata (config/kanata.kbd) sends F13-F17 on ` + 1..5/q and
  # switches its own layer; skhd switches the input source to match.
  # Runs the copy darwin.nix installs and signs at a fixed path, so its
  # Device Control and Data Access permission survives skhd updates.
  services.skhd = {
    enable = true;
    config = ''
      f13 : ${lib.getExe pkgs.macism} com.apple.keylayout.ABC
      f14 : ${lib.getExe pkgs.macism} com.apple.keylayout.Russian
      f15 : ${lib.getExe pkgs.macism} com.apple.inputmethod.Korean.2SetKorean
      f16 : ${lib.getExe pkgs.macism} com.apple.keylayout.Kazakh
      f17 : ${lib.getExe pkgs.macism} com.apple.inputmethod.Kotoeri.RomajiTyping.Japanese
    '';
  };
  launchd.agents.skhd.config.ProgramArguments = lib.mkForce [
    "/Library/Application Support/skhd/skhd"
  ];

  # AirPlay Receiver off; it listens on all interfaces.
  targets.darwin.currentHostDefaults."com.apple.controlcenter".AirplayReceiverEnabled = false;

  # Screenshot folder (system.defaults.screencapture in darwin.nix).
  home.activation.screenshotDir = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run mkdir -p "$HOME/Pictures/Screenshots"
  '';

  # Make macOS rescan Home Manager fonts.
  home.activation.refreshFonts = lib.hm.dag.entryAfter [ "linkGeneration" "onFilesChange" ] ''
    if [ -d "$HOME/Library/Fonts/HomeManager" ]; then
      run find "$HOME/Library/Fonts" -type d -exec touch {} +
    fi
  '';

  # Helium as default browser; skips set ones so macOS doesn't re-prompt.
  home.activation.defaultBrowser = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    for target in http https public.html public.xhtml; do
      if [ "$(${pkgs.duti}/bin/duti -d "$target" 2>/dev/null)" != "net.imput.helium" ]; then
        run ${pkgs.duti}/bin/duti -s net.imput.helium "$target" all
      fi
    done
  '';

  # Raycast keeps quicklinks in its own encrypted database, so this is a
  # file for Raycast's "Import Quicklinks" command. The import has no alias
  # field: set each alias by hand in Settings → Extensions → Quicklinks.
  xdg.configFile."raycast/quicklinks.json".text =
    let
      link = alias: name: url: {
        name = "${name} (${alias})";
        link = url;
        openWith = "Helium";
      };
    in
    builtins.toJSON [
      (link "lw" "LessWrong" "https://www.lesswrong.com/")
      (link "af" "Alignment Forum" "https://www.alignmentforum.org/")
      (link "wk" "Wikipedia" "https://en.wikipedia.org/")
      (link "wkt" "Wiktionary" "https://en.wiktionary.org/")
      (link "gh" "GitHub" "https://github.com/")
      (link "ppg" "Papago" "https://papago.naver.com/")
      (link "gt" "Google Translate" "https://translate.google.com/")
      (link "hf" "Hugging Face" "https://huggingface.co/")
      (link "fm" "Fastmail" "https://app.fastmail.com/")
      (link "cl" "Claude" "https://claude.ai/")
      (link "hn" "Hacker News" "https://news.ycombinator.com/")
      (link "mw" "Merriam-Webster" "https://www.merriam-webster.com/")
      (link "mwt" "Merriam-Webster Thesaurus" "https://www.merriam-webster.com/thesaurus")
    ];
}
