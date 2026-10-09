{ config, pkgs, ... }:

{
  home.username = "alisher";
  home.homeDirectory = "/Users/alisher";
  home.stateVersion = "25.11";

  # Provides the `home-manager` command.
  programs.home-manager.enable = true;

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

    # spelling
    enchant
    hunspell

    # misc
    restic
  ];

  programs.fish = {
    enable = true;
    shellInit = ''
      set -g fish_greeting
      set -gx EDITOR nvim
      set -gx BUN_INSTALL $HOME/.bun
    '';
    interactiveShellInit = ''
      set -gx GPG_TTY (tty)
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
    "$HOME/.local/bin"
    "/Applications/Ghostty.app/Contents/MacOS"
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

  programs.gh = {
    enable = true;
    settings = {
      git_protocol = "https";
      aliases.co = "pr checkout";
    };
  };

  # Out-of-store symlink so lazy.nvim can still write lazy-lock.json.
  xdg.configFile."nvim".source =
    config.lib.file.mkOutOfStoreSymlink "/etc/nix-darwin/config/nvim";

  home.file.".tmux.conf".source = ./config/tmux.conf;
}
