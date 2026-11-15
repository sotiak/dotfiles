{
  flake,
  perSystem,
  pkgs,
  ...
}:
{
  imports = [
    flake.homeModules."home-shared"
    flake.homeModules."home-private"
    flake.homeModules."opencode"
    ./windows-ssh-agent-relay.nix
  ];

  home.stateVersion = "26.05";

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

  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    # The Windows OpenSSH agent relay rejects the unbound mode in WSL,
    # so constrain the workaround to the affected host for now.
    settings."192.168.10.15".PubkeyAuthentication = "yes";
  };

  home.packages = with pkgs; [
    perSystem.llm-agents.dsh
    perSystem.self.agent-browser
    perSystem.self.gemini-cli
    perSystem.self.mo
    perSystem.self.t3code
    pcsc-tools
    usbutils
    (writeShellScriptBin "wsl-fix-interop" ''
      set -euo pipefail

      printf '%s\n' ':WSLInterop:M::MZ::/init:PF' | sudo tee /usr/lib/binfmt.d/WSLInterop.conf >/dev/null
      sudo systemctl unmask systemd-binfmt.service
      sudo systemctl restart systemd-binfmt
      sudo systemctl mask systemd-binfmt.service
    '')
  ];

  systemd.user.services = {
    t3code = {
      Unit = {
        Description = "T3 Code server";
      };

      Service = {
        ExecStart = "${perSystem.self.t3code}/bin/t3 serve --lan --no-browser --host 0.0.0.0";
        WorkingDirectory = "%h";
        Restart = "on-failure";
      };

      Install = {
        WantedBy = [ "default.target" ];
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

}
