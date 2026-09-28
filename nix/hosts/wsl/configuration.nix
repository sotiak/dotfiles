{
  config,
  hostName,
  inputs,
  perSystem,
  pkgs,
  ...
}:

{
  imports = [
    inputs.nixos-wsl.nixosModules.default
    inputs.paseo.nixosModules.default
  ];

  system.stateVersion = "26.05";

  nixpkgs.hostPlatform = "x86_64-linux";

  networking.hostName = hostName;

  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    trusted-users = [
      "root"
      "sk"
    ];
    substituters = [
      "https://cache.nixos.org"
      "https://nix-community.cachix.org"
      "https://cache.numtide.com"
    ];
    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
    ];
  };

  wsl = {
    enable = true;
    defaultUser = "sk";

    interop = {
      register = true;
    };

    wslConf = {
      user.default = "sk";
      boot.systemd = true;

      interop = {
        enabled = true;
        appendWindowsPath = false;
      };
    };

    ssh-agent = {
      enable = true;
      users = [ "sk" ];
    };

    usbip = {
      enable = true;
      autoAttach = [ "2-1" ];
    };
  };

  programs.zsh.enable = true;

  services.tailscale.enable = true;

  services.openssh.enable = true;

  virtualisation.docker.enable = true;

  services.pcscd = {
    enable = true;
    plugins = [ pkgs.ccid ];
  };

  services.paseo = {
    enable = true;
    user = "sk";
    group = "users";
    dataDir = "${config.users.users.sk.home}/.paseo";
    inheritUserEnvironment = true;
    package = perSystem.paseo.default.override {
      # Recomputed for the nixpkgs revision locked by the Paseo input.
      npmDepsHash = "sha256-9UWtpZrCdyYyGq3HGNgSpU1+2Imu3oYqtSumq2DtANc=";
    };

    environment = {
      SSH_AUTH_SOCK = "${config.users.users.sk.home}/.ssh/agent.sock";
    };
  };

  security.sudo.wheelNeedsPassword = false;

  time.timeZone = "Asia/Tokyo";
  i18n.defaultLocale = "en_US.UTF-8";

  # VSCode remote server support
  programs.nix-ld.enable = true;

  users.users.sk = {
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "docker"
    ];
    shell = pkgs.zsh;
  };
}
