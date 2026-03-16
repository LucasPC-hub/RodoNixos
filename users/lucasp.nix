{ pkgs, inputs, ... }:

{
  imports = [
    ./shared.nix
    ./programs/dms-config.nix
    inputs.nixvim.homeModules.nixvim
    inputs.dsearch.homeModules.default
  ];

  home.username = "lucasp";
  home.homeDirectory = "/home/lucasp";
  home.stateVersion = "25.05";

  # Pacotes só meus
  home.packages = with pkgs; [
    protonmail-desktop
    proton-pass
    protonvpn-gui
    tidal-hifi
    jetbrains.webstorm
  ];

  programs.dsearch.enable = true;

  home.sessionVariables = {
    EDITOR = "vim";
    QT_QPA_PLATFORMTHEME = "gtk3";
    TERMINAL = "kitty";
    BROWSER = "zen-beta";
    FILES = "thunar";
  };

  # Cedilha (ç/Ç) com dead_acute + c
  home.file.".XCompose".text = ''
    include "%L"
    <dead_acute> <c> : "ç" U00E7
    <dead_acute> <C> : "Ç" U00C7
  '';

  dconf.settings = {
    "org/gnome/desktop/interface" = {
      gtk-theme = "adw-gtk3-dark";
      color-scheme = "prefer-dark";
    };
  };
}
