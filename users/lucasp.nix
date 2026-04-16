{ pkgs, inputs, lib, ... }:

{
  imports = [
    ./shared.nix
    ./programs/niri-sync.nix
    ./programs/jetbrains.nix
    inputs.dsearch.homeModules.default
  ];

  home.username = "lucasp";
  home.homeDirectory = "/home/lucasp";
  home.stateVersion = "25.05";

  # Pacotes só meus
  home.packages = with pkgs; [
  rclone
    protonmail-desktop
    proton-pass
    proton-vpn
    tidal-hifi
    zed-editor
    opencode
    ghostty
    inputs.t3code.packages.${pkgs.stdenv.hostPlatform.system}.default
    inputs.cmux.packages.${pkgs.stdenv.hostPlatform.system}.default
    jamesdsp
    remmina
    freerdp
  ];

  programs.dsearch.enable = true;

  home.sessionVariables = {
    EDITOR = "vim";
    QT_QPA_PLATFORMTHEME = "gtk3";
    TERMINAL = "kitty";
    BROWSER = "zen-beta";
    FILES = "thunar";
    NIXOS_OZONE_WL = "1";
    GSETTINGS_SCHEMA_DIR = "${pkgs.gsettings-desktop-schemas}/share/gsettings-schemas/${pkgs.gsettings-desktop-schemas.name}/glib-2.0/schemas";
    XDG_DATA_DIRS = "$XDG_DATA_DIRS:${pkgs.gsettings-desktop-schemas}/share/gsettings-schemas/${pkgs.gsettings-desktop-schemas.name}:${pkgs.gtk3}/share/gsettings-schemas/${pkgs.gtk3.name}:${pkgs.shared-mime-info}/share";
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
      color-scheme = lib.mkForce "prefer-dark";
    };
  };
}
