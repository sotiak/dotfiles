{
  inputs,
  perSystem,
  pkgs,
  system,
  ...
}:

let
  # git-hooks currently omits x86_64-darwin from its flake outputs.
  git-hooks =
    inputs.git-hooks.lib.${system} or (import (inputs.git-hooks.outPath + "/nix") {
      nixpkgs = inputs.nixpkgs.outPath;
      inherit system;
      isFlakes = true;
    });
  mcpNixos =
    if pkgs.stdenv.hostPlatform.isDarwin then
      let
        python3Packages = pkgs.python3Packages.overrideScope (
          _: prev: {
            py-key-value-aio = prev.py-key-value-aio.overridePythonAttrs (_: {
              # Avoid a test-only DuckDB -> PyArrow dependency; arrow-cpp is broken on Intel Darwin.
              nativeCheckInputs = [ ];
            });
          }
        );
      in
      pkgs.mcp-nixos.override { inherit python3Packages; }
    else
      pkgs.mcp-nixos;
  preCommitCheck = git-hooks.run {
    src = ../.;
    package = pkgs.prek;
    hooks = {
      actionlint.enable = true;
      pinact = {
        enable = true;
        package = pkgs.pinact;
        entry = "${pkgs.pinact}/bin/pinact run --fix=false --no-api";
        files = "^\\.github/workflows/.*\\.ya?ml$";
      };
      treefmt = {
        enable = true;
        package = perSystem.self.formatter;
      };
    };
  };
in
pkgs.mkShellNoCC {
  inherit (preCommitCheck) shellHook;

  packages =
    (with pkgs; [
      nixd
      nil
      statix
      deadnix
      opentofu
    ])
    ++ [ mcpNixos ]
    ++ preCommitCheck.enabledPackages;

}
