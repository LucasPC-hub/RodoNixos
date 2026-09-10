{ pkgs, inputs, ... }:

let
  system = pkgs.stdenv.hostPlatform.system;
in
{
  # Pacotes que TODO host recebe
  environment.systemPackages = with pkgs; [
    git
    vim
    neovim
    wget
    curl
    htop
    unzip
    ripgrep
    fd
    fzf
    jq
    tree
    pciutils
    inputs.claude-code.packages.${system}.default
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
    firefox-devedition
    discord
    thunar
    adw-gtk3
    kdePackages.qt6ct
    colloid-icon-theme
    easyeffects
    calf
    bubblewrap
    wl-clipboard # needed for image paste in Claude Code
    cifs-utils
    tcpdump
    arping
    nettools
  ];

  programs.fish.enable = true;
  programs.appimage = {
    enable = true;
    binfmt = true;
  };
  security.polkit.enable = true;

  services.gnome.gnome-keyring.enable = true;
  security.pam.services.greetd.enableGnomeKeyring = true;
  programs.seahorse.enable = true;
}
