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
    inputs.zen-browser.packages.${system}.default
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
  security.polkit.enable = true;
}
