{ pkgs, inputs, ... }:

{
  imports = [
    ./shared.nix
    inputs.nixvim.homeModules.nixvim
  ];

  home.username = "lucasp";
  home.homeDirectory = "/home/lucasp";
  home.stateVersion = "25.05";

  # Pacotes só meus
  home.packages = with pkgs; [

  ];

  home.sessionVariables = {
    EDITOR = "vim";
  };
}
