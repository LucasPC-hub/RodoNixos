# ┌─────────────────────────────────────────────────────────────────────────┐
# │ PLACEHOLDER — o rodo-install REGENERA este arquivo na instalação          │
# │ (`nixos-generate-config --no-filesystems`), com os módulos de kernel      │
# │ reais da máquina alvo.                                                    │
# │                                                                           │
# │ NÃO declara fileSystems: o particionamento e os mounts vêm do disko       │
# │ (./disko.nix). Aqui ficam só kernel modules + microcode + hostPlatform.   │
# └─────────────────────────────────────────────────────────────────────────┘
{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  boot.initrd.availableKernelModules = [ "xhci_pci" "nvme" "usbhid" "sd_mod" "ahci" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
