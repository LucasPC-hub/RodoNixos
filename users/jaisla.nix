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
    nautilus
    obsidian
    pavucontrol
    vlc
    remmina
    meld
    zapzap
    (pkgs.symlinkJoin {
      name = "dbeaver-bin-wrapped";
      paths = [ pkgs.dbeaver-bin ];
      buildInputs = [ pkgs.makeWrapper ];
      postBuild = ''
        wrapProgram $out/bin/dbeaver \
          --set GDK_BACKEND x11 \
          --set _JAVA_AWT_WM_NONREPARENTING 1 \
          --set _JAVA_OPTIONS "-Dsun.java2d.uiScale=1 -Dswt.autoScale=200"
      '';
    })
    (jetbrains.withJetbrainsWrapper pkgs.jetbrains.webstorm)
    (jetbrains.withJetbrainsWrapper pkgs.jetbrains.datagrip)
    zed-editor
    jdt-language-server
    collabora-online
    aseprite
  ];

  home.pointerCursor = {
    gtk.enable = true;
    package = pkgs.capitaine-cursors;
    name = "capitaine-cursors";
    size = 24;
  };

  home.sessionVariables = {
    EDITOR = "vim";
    QT_QPA_PLATFORMTHEME = "gtk3";
    TERMINAL = "kitty";
    BROWSER = "zen-beta";
    FILES = "nautilus";
    NIXOS_OZONE_WL = "1";
  };
    # Cedilha (ç/Ç) com dead_acute + c
    home.file.".XCompose".text = ''
      include "%L"
      <dead_acute> <c> : "ç" U00E7
      <dead_acute> <C> : "Ç" U00C7
    '';
}
