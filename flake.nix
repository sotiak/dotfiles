{
  description = "Home Manager configuration of sk";

  nixConfig = {
    extra-substituters = [
      "https://cache.nixos.org"
      "https://nix-community.cachix.org"
      "https://cache.numtide.com"
      "https://sotiak.cachix.org"
    ];
    extra-trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
      "sotiak.cachix.org-1:J7pEDpw1lZj5xF0P0MtvYKPYp47hrViSpydBa5uvWR4="
    ];
  };

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    # Nixpkgs 26.11 dropped x86_64-darwin; keep the Intel Mac on its final supported release.
    nixpkgs-darwin.url = "github:nixos/nixpkgs/nixpkgs-26.05-darwin";
    blueprint = {
      url = "github:numtide/blueprint";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager-darwin = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs-darwin";
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-wsl.url = "github:nix-community/NixOS-WSL/main";
    paseo.url = "github:getpaseo/paseo/v0.9.1";
    git-hooks = {
      url = "github:cachix/git-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-utils.url = "github:numtide/flake-utils";
    treefmt = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    llm-agents.url = "github:numtide/llm-agents.nix";
  };

  outputs =
    inputs:
    let
      linux = inputs.blueprint {
        inherit inputs;
        prefix = "nix/";
        systems = [ "x86_64-linux" ];
      };
      darwinInputs = inputs // {
        nixpkgs = inputs.nixpkgs-darwin;
        home-manager = inputs.home-manager-darwin;
      };
      darwin = inputs.blueprint {
        inputs = darwinInputs;
        prefix = "nix/darwin/";
        systems = [ "x86_64-darwin" ];
      };
      devShells =
        inputs.flake-utils.lib.eachSystem
          [
            "x86_64-linux"
            "x86_64-darwin"
          ]
          (
            system:
            let
              systemInputs = if system == "x86_64-darwin" then darwinInputs else inputs;
              pkgs = systemInputs.nixpkgs.legacyPackages.${system};
              perSystem = {
                self.formatter = import ./nix/formatter.nix {
                  inputs = systemInputs;
                  inherit pkgs;
                };
              };
            in
            {
              devShells.default = import ./nix/devshell.nix {
                inputs = systemInputs;
                inherit perSystem pkgs system;
              };
            }
          );
    in
    inputs.nixpkgs.lib.recursiveUpdate (inputs.nixpkgs.lib.recursiveUpdate linux darwin) devShells;
}
