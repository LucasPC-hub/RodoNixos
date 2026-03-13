{ pkgs, ... }:

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
  ];

  programs.zsh.enable = true;
  security.polkit.enable = true;
}
