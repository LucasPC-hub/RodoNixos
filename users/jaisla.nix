{ pkgs, ... }:

let
  jetbrains = import ./programs/jetbrains.nix { inherit pkgs; };
in
{
  imports = [
    ./shared.nix
  ];

  home.username = "jaisla";
  home.homeDirectory = "/home/jaisla";
  home.stateVersion = "25.05";

  # Pacotes só da jaisla
  home.packages = with pkgs; [
    obsidian
    pavucontrol
    vlc
    remmina
    meld
    zapzap
    dbeaver-bin
    (jetbrains.withJetbrainsWrapper pkgs.jetbrains.webstorm)
    (jetbrains.withJetbrainsWrapper pkgs.jetbrains.datagrip)
    zed-editor
    collabora-online
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
