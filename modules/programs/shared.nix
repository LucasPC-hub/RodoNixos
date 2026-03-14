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
    inputs.zen-browser.packages.${system}.default
    thunar
    adw-gtk3
    kdePackages.qt6ct
    colloid-icon-theme
  ];

  programs.zsh.enable = true;
  security.polkit.enable = true;
}
