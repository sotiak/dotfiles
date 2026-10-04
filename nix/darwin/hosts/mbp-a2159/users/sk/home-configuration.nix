{ flake, ... }:
{
  imports = [
    flake.homeModules."home-shared"
    flake.homeModules."home-private"
  ];

  home.stateVersion = "26.05";
}
