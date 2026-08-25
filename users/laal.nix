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
    collabora-online
    wl-mirror
    insomnia
  ];

  # Identidade git — aqui e não em users/shared.nix, senão todo mundo
  # commitaria com a conta da laal.
  programs.git.settings.user = {
    name = "laralimamota";
    email = "llmotadev@gmail.com";
  };

  home.pointerCursor = {
    enable = true;
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
