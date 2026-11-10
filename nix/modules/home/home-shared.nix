{
  config,
  flake,
  inputs,
  perSystem,
  pkgs,
  ...
}:

{
  imports = [
    inputs.sops-nix.homeManagerModules.sops
    flake.homeModules."agent-skills"
    flake.homeModules."opencode"
  ];

  xdg.enable = true;

  home = {
    packages =
      (with pkgs; [
        # Shell tools
        bat
        curl
        fzf
        jq
        pure-prompt
        ripgrep
        tree
        unzip
        wget
        helix

        # Development
        ghalint
        gh
        ghq
        git
        actionlint
        betterleaks
        devenv
        pinact
        tig

        # Languages
        clang
        go
        nodejs_24
        pnpm
        rustup
        uv
        zig

        # GPG support
        sops

        # Misc
        ast-grep
        ffmpeg
      ])
      ++ [
        perSystem.self.agent-browser
        perSystem.self.gemini-cli
      ]
      # Pi's official flake also builds for Intel macOS, unlike llm-agents.nix.
      ++ [ perSystem.pi.default ];

    sessionVariables = {
      LC_MESSAGES = "en_US.UTF-8";

      LESSHISTFILE = "${config.xdg.stateHome}/less/history";
    };

    sessionPath = [
      "${config.home.homeDirectory}/.local/bin"
    ];
  };

  xdg.configFile = {
    "git" = {
      source = ../../../config/git;
      recursive = true;
    };
    "tig" = {
      source = ../../../config/tig;
      recursive = true;
    };
    "nvim" = {
      source = ../../../config/nvim;
      recursive = true;
    };
    "wezterm" = {
      source = ../../../config/wezterm;
      recursive = true;
    };
    "zsh/rc.zsh".source = ../../../config/zsh/rc.zsh;
  };

  programs = {
    neovim = {
      enable = true;
      defaultEditor = true;
    };

    zsh = {
      enable = true;
      dotDir = "${config.xdg.configHome}/zsh";

      enableCompletion = true;
      autosuggestion.enable = true;
      syntaxHighlighting.enable = true;
      defaultKeymap = "emacs";

      history = {
        ignoreDups = true;
        ignoreSpace = true;
        share = true;
      };

      envExtra = ''
        [ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"
      '';

      initContent = ''
        autoload -Uz promptinit
        promptinit
        prompt pure

        [ -r "$ZDOTDIR/rc.zsh" ] && source "$ZDOTDIR/rc.zsh"
      '';
    };

    chromium.enable = pkgs.stdenv.hostPlatform.isLinux;

    #atuin = {
    #  enable = true;
    #  enableZshIntegration = true;
    #  flags = [ "--disable-up-arrow" ];
    #  settings = {
    #    auto_sync = true;
    #    enter_accept = false;
    #    style = "compact";
    #    records = true;
    #  };
    #  daemon = {
    #    enable = true;
    #  };
    #};

    zoxide = {
      enable = true;
      enableZshIntegration = true;
    };

    direnv = {
      enable = true;
      enableZshIntegration = true;
      nix-direnv.enable = true;
    };

    mise = {
      enable = true;
      enableZshIntegration = true;
      globalConfig.settings.all_compile = false;
      globalConfig.tools = {
        bun = "latest";
        deno = "latest";
      };
    };

    gpg = {
      enable = true;
      homedir = "${config.xdg.dataHome}/gnupg";
      publicKeys = [
        {
          source = ../../../keys/openpgp/sotiak.asc;
        }
      ];
      scdaemonSettings = {
        disable-ccid = true;
      };
    };

    home-manager.enable = true;
  };

  services.gpg-agent = {
    enable = true;
    enableSshSupport = true;
    defaultCacheTtl = 34560000;
    maxCacheTtl = 34560000;
    extraConfig = ''
      pinentry-program ${pkgs.lib.getExe perSystem.self.pinentry}
    '';
  };

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 7d";
  };
}
