{ inputs, pkgs, ... }:

# Host BASE — padrão da empresa. Copie esta pasta (hosts/base -> hosts/<novo>)
# pra criar uma máquina nova. É auto-suficiente: carrega o toolset padrão
# (bun, bruno, datagrip, zen, dms, vscode/zed via home) + o comum de host
# (fonts, energia, gvfs, conta de usuário). Deixei de fora tudo específico de
# máquina (nvidia, samsung, logitech, droidcam, gaming, mounts do NAS,
# kernelParams de painel) — adicione por host conforme o hardware.
#
# Ao copiar:
#   1. regenere ./hardware.nix (`nixos-generate-config --dir .`)
#   2. troque networking.hostName
#   3. renomeie a conta rodouser (aqui e em users/rodouser.nix) se quiser
#   4. registre o host no flake.nix (nixosConfigurations.<novo>)

{
  imports = [
    ./hardware.nix

    ../../modules/core/boot.nix
    ../../modules/core/nix.nix
    ../../modules/core/locale.nix
    ../../modules/core/networking.nix
    ../../modules/core/openssh.nix

    # Toolset padrão da empresa
    ../../modules/programs/shared.nix        # zen browser, claude, CLIs base
    ../../modules/programs/dev.nix           # bun, bruno, datagrip, docker, nix-ld
    ../../modules/programs/openfortivpn.nix  # VPN corporativa (FortiClient)

    # Desktop
    ../../modules/desktop/dms.nix            # DankMaterialShell + niri
    ../../modules/desktop/stylix.nix

    # Hardware genérico (o específico de máquina fica por host)
    ../../modules/hardware/audio.nix
    ../../modules/hardware/bluetooth.nix
    ../../modules/hardware/printing.nix
  ];

  # Overlay do kernel CachyOS
  nixpkgs.overlays = [ inputs.nix-cachyos-kernel.overlays.pinned ];

  # Conta padrão. Renomeie (aqui + users/rodouser.nix + flake.nix) por máquina.
  users.users.rodouser = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "video" "input" "docker" ];
    shell = pkgs.fish;
  };

  networking.hostName = "rodo-base";

  # Segredos por pessoa (agenix). Preencha por host — exemplo:
  # age.secrets = {
  #   aws-credentials = {
  #     file = ../../secrets/aws-credentials.age;
  #     path = "/home/rodouser/.aws/credentials";
  #     owner = "rodouser";
  #     group = "users";
  #     mode = "600";
  #   };
  # };

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
    noto-fonts-color-emoji
    noto-fonts-cjk-sans
    noto-fonts-cjk-serif
    material-symbols
    material-icons
  ];

  system.stateVersion = "25.05";
}
