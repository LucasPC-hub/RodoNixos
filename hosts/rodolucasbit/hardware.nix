# Provisório até o primeiro rebuild no notebook: troque por
# /etc/nixos/hosts/rodolucasbit/hardware.nix, que o rodo-install gerou com os
# módulos reais da máquina (`nixos-generate-config --no-filesystems`), e
# commite. Sem fileSystems: os mounts vêm do disko (./disko.nix).
{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  # vmd/thunderbolt: o i5-12450H pode deixar o NVMe atrás do VMD da Intel.
  boot.initrd.availableKernelModules = [ "xhci_pci" "thunderbolt" "vmd" "nvme" "usbhid" "sd_mod" "ahci" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
