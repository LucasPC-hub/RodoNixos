{ inputs, pkgs, ... }:

{
  imports = [
    ./hardware.nix

    ../../modules/core/boot.nix
    ../../modules/core/nix.nix
    ../../modules/core/locale.nix
    ../../modules/core/networking.nix
    ../../modules/core/openssh.nix
    ../../modules/programs/shared.nix
    ../../modules/programs/dev.nix
    ../../modules/programs/gaming.nix
    ../../modules/hardware/nvidia.nix
    ../../modules/programs/openfortivpn.nix
    ../../modules/desktop/dms.nix
    ../../modules/hardware/audio.nix
    ../../modules/hardware/bluetooth.nix
    ../../modules/hardware/droidcam.nix
    ../../modules/hardware/logitech.nix
    ../../modules/hardware/printing.nix
  ];

  # Overlay do kernel CachyOS
  nixpkgs.overlays = [ inputs.nix-cachyos-kernel.overlays.pinned ];

  # Usuários deste host
  users.users.lucasp = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "video" "input" "docker" ];
    shell = pkgs.zsh;
  };

  # Kernel params específicos desta máquina
  boot.kernelParams = [ "video=eDP-1:2880x1800@120" ];
  boot.kernelModules = [ "i2c-dev" ];

  networking.hostName = "rodolucas";

  # Bateria e energia
  services.upower.enable = true;
  services.power-profiles-daemon.enable = true;

  # Montar dispositivos (MTP, USB, etc) + thumbnails no file manager
  services.gvfs.enable = true;
  services.tumbler.enable = true;

  # Fonts
  fonts.packages = with pkgs; [
    fira-sans
    roboto
    jetbrains-mono
    nerd-fonts._0xproto
    nerd-fonts.droid-sans-mono
    nerd-fonts.fantasque-sans-mono
    noto-fonts
    noto-fonts-emoji
    noto-fonts-cjk-sans
    noto-fonts-cjk-serif
    material-symbols
    material-icons
  ];

  system.stateVersion = "25.05";
}
