{ pkgs, ... }:

let
  jetbrains = import ./programs/jetbrains.nix { inherit pkgs; };
in
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
    dbeaver-bin
    (jetbrains.withJetbrainsWrapper pkgs.jetbrains.webstorm)
    (jetbrains.withJetbrainsWrapper pkgs.jetbrains.datagrip)
    zed-editor
    libreoffice-qt6-fresh
    wl-mirror
    firefox-devedition
    insomnia
  ];

  home.pointerCursor = {
    gtk.enable = true;
    x11.enable = true;
    package = pkgs.adwaita-icon-theme;
    name = "Adwaita";
    size = 24;
  };

  home.sessionVariables = {
    EDITOR = "vim";
    QT_QPA_PLATFORMTHEME = "gtk3";
    TERMINAL = "kitty";
    BROWSER = "zen-beta";
    FILES = "thunar";
    NIXOS_OZONE_WL = "1";
  };
}
