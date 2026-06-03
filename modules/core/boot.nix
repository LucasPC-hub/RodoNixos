{ pkgs, ... }:

{
  # Kernel CachyOS via xddxdd/nix-cachyos-kernel
  boot.kernelPackages = pkgs.cachyosKernels.linuxPackages-cachyos-latest;

  boot.loader = {
    systemd-boot.enable = true;
    systemd-boot.configurationLimit = 5; # mantém só as 5 últimas gerações no menu de boot
    efi.canTouchEfiVariables = true;
  };
}
