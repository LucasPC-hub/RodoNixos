{ pkgs, ... }:

{
  # Kernel CachyOS via xddxdd/nix-cachyos-kernel
  boot.kernelPackages = pkgs.cachyosKernels.linuxPackages-cachyos-latest;

  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
  };
}
