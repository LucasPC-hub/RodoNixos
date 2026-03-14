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
  ];

  programs.zsh.enable = true;
  security.polkit.enable = true;
}
