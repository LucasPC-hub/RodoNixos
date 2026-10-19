{ inputs, pkgs, lib, ... }:

# Notebook do lucasbit: Acer Aspire 5 A515-57 (i5-12450H, Intel UHD, 24 GB,
# NVMe 256 GB). Mesmo ambiente da laal (hosts/laal/comum.nix + plugins da
# loja do DMS dela). Instalado pelo rodo-install, por isso o disco vem do
# disko (./disko.nix) e o hardware.nix não declara fileSystems.
{
  imports = [
    ./hardware.nix
    inputs.disko.nixosModules.default
    ./disko.nix
    ../laal/comum.nix
    ./dms-loja.nix
  ];

  networking.hostName = "rodolucasbit";

  users.users.lucasbit = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "video" "input" "docker" ];
    shell = pkgs.fish;
  };

  # Sem o cache do kernel CachyOS (modules/core/nix.nix): o servidor foi
  # invadido em 15/10/2026 (github.com/xddxdd/nix-cachyos-kernel/issues/110)
  # e o kernel daqui é o zen do cache.nixos.org. Não confiar na chave dele.
  nix.settings.substituters = lib.mkForce [ "https://cache.nixos.org/" ];
  nix.settings.trusted-public-keys = lib.mkForce [
    "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
  ];

  # Teto de paralelismo de build (mesmo motivo do host da laal). Com o padrão
  # (max-jobs=auto, cores=0) são até 12 builds x 12 compiladores nos 12
  # threads; o primeiro rebuild compila coisas fora do cache (qs-bitwarden em
  # Rust, quickshell/cpptrace em C++, dms em Go) e o kernel matou o rustc por
  # falta de memória. 2 jobs x 6 cores ocupa os 12 threads sem estourar os 24 GB.
  nix.settings = {
    max-jobs = 2;
    cores = 6;
  };

  # Intel UHD (Alder Lake): decodificação de vídeo por hardware (VA-API/QSV).
  hardware.graphics.extraPackages = with pkgs; [ intel-media-driver vpl-gpu-rt ];
  environment.sessionVariables.LIBVA_DRIVER_NAME = "iHD";

  # Controle térmico da Intel e atualização de firmware/BIOS pelo fwupd.
  services.thermald.enable = true;
  services.fwupd.enable = true;

  # Neste modelo o s2idle gasta bateria rápido com a tampa fechada; o S3
  # funciona (ArchWiki, Laptop/Acer). Se a BIOS não oferecer S3, o kernel
  # ignora e continua no s2idle.
  boot.kernelParams = [ "mem_sleep_default=deep" ];

  # Swap por zram (o disko não cria partição de swap)
  zramSwap.enable = true;

  system.stateVersion = "25.05";
}
