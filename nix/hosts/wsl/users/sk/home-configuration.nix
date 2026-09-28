{
  flake,
  perSystem,
  pkgs,
  ...
}:
let
  opencode = perSystem.llm-agents.opencode;
in
{
  imports = [
    flake.homeModules."home-shared"
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

  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    # The Windows OpenSSH agent relay rejects the unbound mode in WSL,
    # so constrain the workaround to the affected host for now.
    settings."192.168.10.15".PubkeyAuthentication = "yes";
  };

  home.packages =
    (with perSystem.llm-agents; [
      agent-browser
      gemini-cli
      opencode
    ])
    ++ (with pkgs; [
      perSystem.self.mo
      pcsc-tools
      usbutils
      (writeShellScriptBin "wsl-fix-interop" ''
        set -euo pipefail

        printf '%s\n' ':WSLInterop:M::MZ::/init:PF' | sudo tee /usr/lib/binfmt.d/WSLInterop.conf >/dev/null
        sudo systemctl unmask systemd-binfmt.service
        sudo systemctl restart systemd-binfmt
        sudo systemctl mask systemd-binfmt.service
      '')
    ]);

  systemd.user.services.opencode-web = {
    Unit = {
      Description = "OpenCode Web server";
    };

    Service = {
      ExecStart = "${opencode}/bin/opencode serve --hostname 127.0.0.1 --port 4096";
      Restart = "on-failure";
    };

    Install = {
      WantedBy = [ "default.target" ];
    };
  };

}
