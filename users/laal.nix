{ pkgs, ... }:

{
  imports = [
    ./shared.nix
  ];

  home.username = "laal";
  home.homeDirectory = "/home/laal";
  home.stateVersion = "25.05";

  # Pacotes só da laal
  home.packages = with pkgs; [
    obsidian
    pavucontrol
    vlc
    remmina
    meld
    zapzap
  ];

  home.sessionVariables = {
    EDITOR = "vim";
    QT_QPA_PLATFORMTHEME = "gtk3";
    TERMINAL = "kitty";
    BROWSER = "zen-beta";
    FILES = "thunar";
    NIXOS_OZONE_WL = "1";
  };
}
