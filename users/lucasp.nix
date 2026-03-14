{ pkgs, inputs, ... }:

{
  imports = [
    ./shared.nix
    inputs.nixvim.homeModules.nixvim
    inputs.dsearch.homeModules.default
  ];

  home.username = "lucasp";
  home.homeDirectory = "/home/lucasp";
  home.stateVersion = "25.05";

  # Pacotes só meus
  home.packages = with pkgs; [

  ];

  programs.dsearch.enable = true;

  home.sessionVariables = {
    EDITOR = "vim";
    QT_QPA_PLATFORMTHEME = "gtk3";
  };
}
