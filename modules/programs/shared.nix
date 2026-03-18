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
    inputs.claude-desktop.packages.${system}.claude-desktop-with-fhs
    inputs.zen-browser.packages.${system}.default
    discord
    thunar
    adw-gtk3
    kdePackages.qt6ct
    (colloid-icon-theme.override { schemeVariants = [ "all" ]; })
    easyeffects
    calf
  ];

  programs.zsh.enable = true;
  security.polkit.enable = true;
}
