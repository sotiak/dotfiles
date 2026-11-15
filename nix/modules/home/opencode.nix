{ pkgs, ... }:

{
  home.packages = [
    pkgs.opencode
    pkgs.mcp-nixos
  ];

  xdg.configFile = {
    "opencode/opencode.jsonc".source = ../../../config/opencode/opencode.jsonc;
    "opencode/AGENTS.md".source = ../../../config/opencode/AGENTS.md;
  };

  home.sessionVariables.OPENCODE_DISABLE_FREE_MODELS = "1";
}
