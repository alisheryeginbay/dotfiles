{ config, lib, pkgs, ... }:

{
  home.username = "alisher";
  home.homeDirectory = "/Users/alisher";
  home.stateVersion = "25.11";

  # Provides the `home-manager` command.
  programs.home-manager.enable = true;

  # Expire old home-manager generations so the system GC can collect them.
  nix.gc = {
    automatic = true;
    dates = "weekly";
  };
  # The module passes `nix.gc.options` as a single argv element on darwin,
  # which nix-collect-garbage rejects, so set the arguments directly.
  launchd.agents.nix-gc.config.ProgramArguments = lib.mkForce [
    "${pkgs.nix}/bin/nix-collect-garbage"
    "--delete-older-than"
    "30d"
  ];

  home.packages = with pkgs; [
    # shell utilities
    neovim
    tmux
    bat
    eza
    ripgrep
    fastfetch

    # dev
    bun
    fnm
    uv
    rustup
    ruff
    ty
    shfmt
    lua-language-server
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

    # LaTeX for org previews/export and the occasional paper. Add packages
    # here when a document fails with "File `foo.sty' not found".
    (texliveSmall.withPackages (ps: with ps; [
      latexmk
      dvisvgm # org-preview-latex-default-process
      digestif # LSP for eglot
      # org-latex-default-packages-alist beyond scheme-small
      wrapfig
      ulem
      capt-of
      # papers
      biblatex
      biber
    ]))

    # R plus the "recommended" packages the official installer bundles.
    # Add CRAN packages to the list (install.packages() won't persist).
    (rWrapper.override {
      packages = with rPackages; [
        boot class cluster codetools foreign KernSmooth lattice MASS Matrix
        mgcv nlme nnet rpart spatial survival
      ];
    })

    # spelling
    enchant
    hunspell

    # apps (copied to ~/Applications/Home Manager Apps)
    anki-bin
    slack
    # Dock launcher: a new frame on the Emacs daemon (see launchd.agents.emacs).
    # Emacs.app itself would start a separate, cold Emacs that Cmd-Q quits.
    (pkgs.runCommand "emacs-client-app" { } ''
      app="$out/Applications/Emacs Client.app/Contents"
      mkdir -p "$app/MacOS" "$app/Resources"
      cp ${config.programs.emacs.finalPackage}/Applications/Emacs.app/Contents/Resources/Emacs.icns "$app/Resources/"
      cat > "$app/Info.plist" <<EOF
      <?xml version="1.0" encoding="UTF-8"?>
      <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
      <plist version="1.0">
      <dict>
        <key>CFBundleName</key><string>Emacs Client</string>
        <key>CFBundleIdentifier</key><string>org.gnu.EmacsClient</string>
        <key>CFBundleExecutable</key><string>emacs-client</string>
        <key>CFBundleIconFile</key><string>Emacs.icns</string>
        <key>CFBundlePackageType</key><string>APPL</string>
      </dict>
      </plist>
      EOF
      cat > "$app/MacOS/emacs-client" <<EOF
      #!/bin/sh
      # -a "": start a daemon if the launchd one isn't up. The -e raises the
      # new frame, which otherwise can open behind the current app.
      exec ${config.programs.emacs.finalPackage}/bin/emacsclient -c -n -a "" \
        -e '(select-frame-set-input-focus (selected-frame))'
      EOF
      chmod +x "$app/MacOS/emacs-client"
    '')

    # fonts
    aporetic

    # misc
    restic
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
    '';
    interactiveShellInit = ''
      fnm env --use-on-cd --shell fish | source
    '';
    shellAliases = {
      ls = "eza --all --long --group --group-directories-first --icons --header --time-style long-iso";
      grt = ''cd "$(git rev-parse --show-toplevel)"'';
      cat = "bat";
      cc = "claude --dangerously-skip-permissions";
      e = "emacsclient -n";
      ec = "emacsclient -c -n";
    };
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
    options = [ "--cmd" "cd" ];
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
      key = "~/.ssh/git.pub";
      signByDefault = true;
    };
    settings = {
      user.name = "Alisher Yeginbay";
      user.email = "alisher@yeginbay.com";
      init.defaultBranch = "main";
      lfs.concurrenttransfers = 3;
      "lfs \"customtransfer.xet\"" = {
        path = "git-xet";
        args = "transfer";
        concurrent = true;
      };
    };
  };

  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    settings."github.com" = {
      IdentityFile = "~/.ssh/git";
      AddKeysToAgent = "yes";
      UseKeychain = "yes";
    };
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
  xdg.configFile."nvim".source =
    config.lib.file.mkOutOfStoreSymlink "/etc/nix-darwin/config/nvim";

  home.file.".tmux.conf".source = ./config/tmux.conf;

  programs.emacs = {
    enable = true;
    package = pkgs.emacs;
    extraPackages = epkgs: with epkgs; [
      # evil
      evil
      evil-collection
      evil-nerd-commenter
      evil-mc
      general
      disable-mouse

      # completion
      vertico
      orderless
      marginalia
      consult
      corfu
      cape

      # editing
      apheleia
      olivetti
      jinx
      mw-thesaurus
      pdf-tools
      exec-path-from-shell
      magit

      # languages
      eldoc-box
      code-cells
      pet
      ess
      auctex
      cdlatex
      (treesit-grammars.with-grammars (g: with g; [
        tree-sitter-bash
        tree-sitter-markdown
        tree-sitter-markdown-inline
        tree-sitter-rust
      ]))

      # org
      org-roam
      org-super-agenda
      org-edna
      org-noter
      citar
    ];
  };

  # Config is versioned here; everything else in ~/.config/emacs (elpa,
  # caches, org-roam.db, secrets.el, custom.el) stays local state.
  # Out-of-store links keep the files editable from Emacs.
  xdg.configFile."emacs/early-init.el".source =
    config.lib.file.mkOutOfStoreSymlink "/etc/nix-darwin/config/emacs/early-init.el";
  xdg.configFile."emacs/init.el".source =
    config.lib.file.mkOutOfStoreSymlink "/etc/nix-darwin/config/emacs/init.el";
  xdg.configFile."emacs/lisp".source =
    config.lib.file.mkOutOfStoreSymlink "/etc/nix-darwin/config/emacs/lisp";
  xdg.configFile."emacs/dict".source =
    config.lib.file.mkOutOfStoreSymlink "/etc/nix-darwin/config/emacs/dict";

  launchd.agents.emacs = {
    enable = true;
    config = {
      # Run the binary inside Emacs.app so macOS treats the daemon as
      # org.gnu.Emacs and applies its per-app defaults (AppleFontSmoothing).
      ProgramArguments = [
        "${config.programs.emacs.finalPackage}/Applications/Emacs.app/Contents/MacOS/Emacs"
        "--fg-daemon"
      ];
      RunAtLoad = true;
      KeepAlive = true;
      StandardOutPath = "/tmp/emacs-daemon.out.log";
      StandardErrorPath = "/tmp/emacs-daemon.err.log";
    };
  };

  # Personal dictionary; out-of-store so spell checkers can add words.
  xdg.configFile."enchant/en_US.dic".source =
    config.lib.file.mkOutOfStoreSymlink "/etc/nix-darwin/config/enchant/en_US.dic";

  xdg.configFile."1Password/ssh/agent.toml".text = ''
    [[ssh-keys]]
    vault = "Personal"
  '';
}
