{ perSystem, pkgs, ... }:

let
  t3code = perSystem.llm-agents.t3code;
in
t3code.override {
  # llm-agents bundles OpenCode 1.19.5; T3 recommends >=2.0.18, and OpenCode Go needs v2.
  providerPackages = [ pkgs.opencode ] ++ t3code.providerPackages;
}
