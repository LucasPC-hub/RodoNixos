# ┌─────────────────────────────────────────────────────────────────────────┐
# │ PLACEHOLDER — REGENERE ESTE ARQUIVO AO COPIAR O HOST BASE                 │
# │                                                                           │
# │   sudo nixos-generate-config --dir /etc/nixos/tmp                         │
# │   cp /etc/nixos/tmp/hardware-configuration.nix ./hardware.nix             │
# │                                                                           │
# │ (ou deixe seu script de provisionamento gerar isto.)                      │
# │                                                                           │
# │ Os device= abaixo são fictícios (by-label). O build do flake avalia, mas  │
# │ a máquina NÃO vai bootar até você trocar por UUIDs/labels reais.          │
# └─────────────────────────────────────────────────────────────────────────┘
{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  boot.initrd.availableKernelModules = [ "xhci_pci" "nvme" "usbhid" "sd_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-label/BOOT";
    fsType = "vfat";
    options = [ "fmask=0077" "dmask=0077" ];
  };

  swapDevices = [ ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
