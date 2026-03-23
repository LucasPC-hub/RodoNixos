{ pkgs, inputs, lib, ... }:

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
  home.packages = let
    withNvidiaOffload = pkg: pkgs.symlinkJoin {
      name = "${pkg.pname or pkg.name}-nvidia";
      paths = [ pkg ];
      buildInputs = [ pkgs.makeWrapper ];
      postBuild = ''
        for bin in $out/bin/*; do
          wrapProgram "$bin" \
            --set __NV_PRIME_RENDER_OFFLOAD 1 \
            --set __GLX_VENDOR_LIBRARY_NAME nvidia \
            --set __VK_LAYER_NV_optimus NVIDIA_only
          done
      '';
    };
  in with pkgs; [
    protonmail-desktop
    proton-pass
    protonvpn-gui
    tidal-hifi
    (withNvidiaOffload jetbrains.webstorm)
    zed-editor
    opencode
  ];

  programs.dsearch.enable = true;

  home.sessionVariables = {
    EDITOR = "vim";
    QT_QPA_PLATFORMTHEME = "gtk3";
    TERMINAL = "kitty";
    BROWSER = "zen-beta";
    FILES = "thunar";
    NIXOS_OZONE_WL = "1";
    GSETTINGS_SCHEMA_DIR = "${pkgs.gsettings-desktop-schemas}/share/glib-2.0/schemas";
    XDG_DATA_DIRS = "$XDG_DATA_DIRS:${pkgs.gsettings-desktop-schemas}/share:${pkgs.shared-mime-info}/share";
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
