{ pkgs, ... }:

{
  # Nixpkgs ships OpenCode 2 on Linux, but only v1 for Intel macOS.
  home.packages = [ pkgs.opencode ];

  xdg.configFile = {
    "opencode/opencode.jsonc".source = ../../../config/opencode/opencode.jsonc;
    "opencode/AGENTS.md".source = ../../../config/opencode/AGENTS.md;
  };

  home.sessionVariables.OPENCODE_DISABLE_FREE_MODELS = "1";
}
