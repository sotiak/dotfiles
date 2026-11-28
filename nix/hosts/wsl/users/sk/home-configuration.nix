{
  config,
  flake,
  lib,
  perSystem,
  pkgs,
  ...
}:
let
  opencodeTelemetry = pkgs.callPackage ./opencode-telemetry.nix { };
in
{
  imports = [
    flake.homeModules."home-shared"
    flake.homeModules."home-private"
    flake.homeModules."opencode"
  ];

  home = {
    stateVersion = "26.05";

    # win32yank.exe for the Neovim clipboard integration
    sessionPath = [ "/mnt/c/tools/bin" ];

    sessionVariables = {
      SOPS_AGE_KEY_FILE = "${config.home.homeDirectory}/.config/sops/age/keys.txt";
    };
  };

  sops.age.keyFile = "${config.home.homeDirectory}/.config/sops/age/keys.txt";

  services.gpg-agent.enableSshSupport = lib.mkForce false;

  xdg.configFile = {
    "git/wsl.gitconfig".text = ''
      [credential]
        helper = /mnt/c/Program\\ Files/Git/mingw64/bin/git-credential-manager.exe

      [gpg]
        program = /mnt/c/Program Files/GnuPG/bin/gpg.exe
    '';
    "zsh/wsl.zsh".source = ../../../../../config/zsh/wsl.zsh;
  };

  programs.chromium.enable = true;

  home.packages = with pkgs; [
    perSystem.llm-agents.dsh
    perSystem.self.agent-browser
    perSystem.self.gemini-cli
    perSystem.self.mo
    opencodeTelemetry
    usbutils
  ];

  systemd.user.services = {
    opencode-telemetry = {
      Unit = {
        Description = "Export OpenCode usage stats to VictoriaMetrics";
      };

      Service = {
        Type = "oneshot";
        ExecStart = "${opencodeTelemetry}/bin/opencode-telemetry";
      };
    };

    dsh-web = {
      Unit = {
        Description = "DeepSeek Harness Web server";
      };

      Service = {
        ExecStart = "${perSystem.llm-agents.dsh}/bin/dsh web --host 127.0.0.1 --port 3080 --no-open";
        Restart = "on-failure";
      };

      Install = {
        WantedBy = [ "default.target" ];
      };
    };
  };

  systemd.user.timers.opencode-telemetry = {
    Unit = {
      Description = "Collect OpenCode usage stats every minute";
    };

    Timer = {
      OnCalendar = "*:0/1";
      AccuracySec = "10s";
    };

    Install = {
      WantedBy = [ "timers.target" ];
    };
  };

}
