{ inputs, pkgs, ... }:

{
  imports = [
    ./hardware.nix

    ../../modules/core/boot.nix
    ../../modules/core/nix.nix
    ../../modules/core/locale.nix
    ../../modules/core/openssh.nix
    ../../modules/programs/shared.nix
    ../../modules/programs/dev.nix
    ../../modules/desktop/dms.nix
    ../../modules/desktop/stylix.nix
    ../../modules/hardware/audio.nix
    ../../modules/hardware/bluetooth.nix
    ../../modules/hardware/printing.nix
    ../../modules/hardware/nvidia.nix
  ];

  # Overlay do kernel CachyOS (mesmo que rodolucas)
  nixpkgs.overlays = [ inputs.nix-cachyos-kernel.overlays.pinned ];

  # Tela nativa do Acer Nitro V15
  boot.kernelParams = [ "video=eDP-1:1920x1080@165" ];

  # Networking — inline pra não puxar o extraHosts do lucasp
  networking.hostName = "laal";
  networking.networkmanager.enable = true;
  networking.firewall.enable = true;

  # Usuária deste host
  users.users.laal = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "video" "input" "docker" ];
    shell = pkgs.fish;
  };

  # Notebook: bateria e energia
  services.upower.enable = true;
  services.power-profiles-daemon.enable = true;

  # Montar dispositivos (MTP, USB) + thumbnails no file manager
  services.gvfs.enable = true;
  services.tumbler.enable = true;

  # Fonts (mesmo set do rodolucas)
  fonts.packages = with pkgs; [
    fira-sans
    roboto
    jetbrains-mono
    nerd-fonts._0xproto
    nerd-fonts.droid-sans-mono
    nerd-fonts.fantasque-sans-mono
    noto-fonts
    noto-fonts-color-emoji
    noto-fonts-cjk-sans
    noto-fonts-cjk-serif
    material-symbols
    material-icons
  ];

  system.stateVersion = "25.05";
}
