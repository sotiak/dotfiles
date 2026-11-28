{
  config,
  flake,
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
    flake.nixosModules.private
  ];

  system.stateVersion = "26.05";

  nixpkgs.hostPlatform = "x86_64-linux";

  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];

  networking.hostName = "e14-wsl";

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
      boot = {
        systemd = true;
        # WSL's protectBinfmt overrides systemd-binfmt, which wipes
        # WSLInterop when nixos-rebuild remounts binfmt_misc.
        protectBinfmt = false;
      };

      interop = {
        enabled = true;
        appendWindowsPath = false;
      };
    };
  };

  programs.zsh.enable = true;

  services.openssh.enable = true;

  # WSL's eth0 MTU can drop to 1280; lower tailscale0 so WireGuard
  # encapsulation does not blackhole large packets.
  systemd.services.tailscaled.serviceConfig.ExecStartPost = [
    "${pkgs.iproute2}/bin/ip link set tailscale0 mtu 1200"
  ];

  virtualisation.docker.enable = true;

  services.paseo = {
    enable = true;
    user = "sk";
    group = "users";
    dataDir = "${config.users.users.sk.home}/.paseo";
    inheritUserEnvironment = true;
    package = perSystem.paseo.default.override {
      npmDepsHash = "sha256-SZV3WTKLb+JhxWNo/jWyx+2sipzfL93YbbqQSihd3Wo=";
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
