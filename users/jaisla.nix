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
    postgresql
    openssl
    nautilus
    obsidian
    brave
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
    libreoffice-fresh
  ];

  # git.enable vem do shared.nix; aqui fica só a delegação das contas.
  programs.git = {
    # Identidade global (trabalho)
    settings.user = {
      name = "jaisla-rodojunior";
      email = "jaisla@rodojunior.com.br";
    };
    # Sempre usa SSH pro GitHub, mesmo que o remote esteja como https://
    settings.url."git@github.com:".insteadOf = "https://github.com/";
    # Nos projetos pessoais, usa a identidade pessoal
    includes = [
      {
        condition = "gitdir:~/home/jaisla/development/pessoal/";
        contents = {
          user = {
            name = "jaislaataides";
            email = "jaisslaataidess@gmail.com";
          };
        };
      }
    ];
  };

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
    GOPATH = "/home/jaisla/development/pessoal/go";
  };

  home.sessionPath = [ "/home/jaisla/development/pessoal/go/bin" ];
    # Cedilha (ç/Ç) com dead_acute + c
    home.file.".XCompose".text = ''
      include "%L"
      <dead_acute> <c> : "ç" U00E7
      <dead_acute> <C> : "Ç" U00C7
    '';
}
