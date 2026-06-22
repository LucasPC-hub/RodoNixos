{ pkgs, inputs, ... }:

let
  jetbrains = import ./programs/jetbrains.nix { inherit pkgs; };
in
{
  imports = [
    ./shared.nix
    inputs.dsearch.homeModules.default
    inputs.helium-browser.homeModules.default
  ];

  home.username = "lucasp";
  home.homeDirectory = "/home/lucasp";
  home.stateVersion = "25.05";

  # Pacotes só meus
  home.packages = with pkgs; [
    deezer-desktop
    deezer-enhanced
    rclone
    protonmail-desktop
    proton-pass
    proton-vpn
    tidal-hifi
    zed-editor
    ghostty
    dig
    qbittorrent
    goofcord
    inputs.t3code.packages.${pkgs.stdenv.hostPlatform.system}.default
    inputs.cmux.packages.${pkgs.stdenv.hostPlatform.system}.default
    jamesdsp
    remmina
    freerdp
    awscli2
    oci-cli
    (jetbrains.withJetbrainsWrapper pkgs.jetbrains.webstorm)
    (jetbrains.withJetbrainsWrapper pkgs.jetbrains.datagrip)
  ];

  programs.dsearch.enable = true;
  programs.helium.enable = true;

  home.sessionVariables = {
    EDITOR = "vim";
    AWS_DEFAULT_REGION = "us-east-1";
    AWS_REGION = "us-east-1";
    # agenix expõe os arquivos via symlink (lrwxrwxrwx); o oci-cli reclama da
    # permissão do link. Os alvos reais são 600, então é seguro silenciar.
    OCI_CLI_SUPPRESS_FILE_PERMISSIONS_WARNING = "True";
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
