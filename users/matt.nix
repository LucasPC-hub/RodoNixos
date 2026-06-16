{ pkgs, ... }:

let
  jetbrains = import ./programs/jetbrains.nix { inherit pkgs; };
in
{
  imports = [
    ./shared.nix
  ];

  home.username = "matt";
  home.homeDirectory = "/home/matt";
  home.stateVersion = "25.05";

  # git.enable vem do shared.nix; aqui fica só a identidade do matt.
  programs.git.settings.user = {
    name = "matheuscara";
    email = "matheus.dias.dev@gmai.com";
  };

  # Pacotes só do matt — apps/CLIs trazidos do Arch.
  # Deduplicados do que já vem de shared.nix e users/programs/* (kitty, fish,
  # starship, yazi, vscode, bat, eza, fastfetch...) e de modules/programs/*
  # (git, gh, docker, bruno, lazydocker, nmap, ripgrep...).
  home.packages = with pkgs; [
    # Apps desktop
    obsidian
    vlc
    pavucontrol
    nextcloud-client
    remmina
    freerdp
    meld
    zapzap
    vesktop
    alacritty

    # Bancos / clientes de API
    dbeaver-bin
    insomnia
    soapui
    termius

    # JetBrains (wrapper c/ offload NVIDIA + toolkit Wayland, igual aos outros)
    (jetbrains.withJetbrainsWrapper pkgs.jetbrains.webstorm)
    (jetbrains.withJetbrainsWrapper pkgs.jetbrains.idea-community)

    # CLIs / TUIs
    btop
    glances
    duf
    micro
    mkcert
    websocat
    unrar
    matugen
  ];

  home.sessionVariables = {
    EDITOR = "vim";
    QT_QPA_PLATFORMTHEME = "gtk3";
    TERMINAL = "kitty";
    BROWSER = "zen-beta";
    FILES = "thunar";
    NIXOS_OZONE_WL = "1";
  };
}
