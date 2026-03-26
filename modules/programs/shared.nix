{ pkgs, inputs, ... }:

let
  system = pkgs.stdenv.hostPlatform.system;
in
{
  # Pacotes que TODO host recebe
  environment.systemPackages = with pkgs; [
    git
    vim
    wget
    curl
    htop
    unzip
    jq
    tree
    pciutils
    inputs.claude-code.packages.${system}.default
    claude-desktop
    (pkgs.symlinkJoin {
      name = "zen-browser-wrapped";
      paths = [ inputs.zen-browser.packages.${system}.default ];
      buildInputs = [ pkgs.makeWrapper ];
      postBuild = ''
        for bin in $out/bin/*; do
          wrapProgram "$bin" --unset GDK_SCALE --unset GDK_DPI_SCALE
        done
      '';
    })
    discord
    thunar
    adw-gtk3
    kdePackages.qt6ct
    (colloid-icon-theme.override { schemeVariants = [ "all" ]; })
    easyeffects
    calf
    bubblewrap
    wl-clipboard # needed for image paste in Claude Code
  ];

  programs.fish.enable = true;
  programs.appimage = {
    enable = true;
    binfmt = true;
  };
  security.polkit.enable = true;
}
