{ pkgs, inputs, ... }:

# Home do usuário padrão da empresa (host base). Renomeie ao provisionar.
# GUI/pessoal fica aqui; CLI/system-wide vem dos módulos (programs/dev.nix etc).

let
  jetbrains = import ./programs/jetbrains.nix { inherit pkgs; };
in
{
  imports = [
    ./shared.nix   # vscode, dms-config, zen, kitty, fish, starship, direnv...
  ];

  home.username = "rodouser";
  home.homeDirectory = "/home/rodouser";
  home.stateVersion = "25.05";

  # Apps GUI padrão da empresa
  home.packages = with pkgs; [
    zed-editor
    (jetbrains.withJetbrainsWrapper pkgs.jetbrains.datagrip)
    (jetbrains.withJetbrainsWrapper pkgs.jetbrains.webstorm)
  ];

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
}
