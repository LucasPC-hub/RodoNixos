{ inputs, pkgs, ... }:

{
  imports = [
    ./hardware.nix
    ./comum.nix
    ./manutencao.nix

    ../../modules/hardware/nvidia.nix
  ];

  # Teto de paralelismo de build. 20 cores pra 31 GiB é apertado: com os
  # padrões (max-jobs=auto, cores=0) uma derivação C++ pesada dispara ~20
  # cc1plus e o kernel mata o compilador por falta de memória — foi o que
  # quebrou o cpptrace (dependência do quickshell/dms). 4 jobs x 5 cores
  # satura os 20 cores sem estourar a RAM.
  nix.settings = {
    max-jobs = 4;
    cores = 5;
  };

  # Overlay do kernel CachyOS (mesmo que rodolucas)
  nixpkgs.overlays = [ inputs.nix-cachyos-kernel.overlays.pinned ];

  # Tela nativa do Acer Nitro V15
  boot.kernelParams = [ "video=eDP-1:1920x1080@165" ];

  networking.hostName = "laal";

  # Usuária deste host
  users.users.laal = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "video" "input" "docker" ];
    shell = pkgs.fish;
  };

  # VPN mesh
  services.tailscale.enable = true;

  # Servidor DLNA: a TV Samsung acha "pc-da-lara" em Source e abre os vídeos
  # de ~/tv. inotify faz arquivo novo aparecer sem reiniciar o serviço.
  services.minidlna = {
    enable = true;
    openFirewall = true;
    settings = {
      friendly_name = "pc-da-lara";
      media_dir = [ "V,/home/laal/tv" ];
      inotify = "yes";
    };
  };
  # /home/laal é 700; a ACL deixa só o usuário minidlna atravessar (sem listar)
  # até ~/tv. Os arquivos lá já são 644.
  systemd.tmpfiles.rules = [ "a+ /home/laal - - - - u:minidlna:x" ];

  system.stateVersion = "25.05";
}
