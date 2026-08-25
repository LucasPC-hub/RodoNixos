{ pkgs, ... }:

{
  # Kernel Zen (pré-compilado no cache.nixos.org; módulo NVIDIA compila local)
  boot.kernelPackages = pkgs.linuxPackages_zen;

  boot.loader = {
    systemd-boot.enable = true;
    systemd-boot.configurationLimit = 5; # mantém só as 5 últimas gerações no menu de boot
    efi.canTouchEfiVariables = true;
  };
}
