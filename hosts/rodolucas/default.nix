{ inputs, pkgs, ... }:

{
  imports = [
    ./hardware.nix

    ../../modules/core/boot.nix
    ../../modules/core/nix.nix
    ../../modules/core/locale.nix
    ../../modules/core/networking.nix
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

  system.stateVersion = "25.05";
}
