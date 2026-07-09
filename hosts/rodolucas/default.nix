{ inputs, pkgs, ... }:

{
  imports = [
    ./hardware.nix

    ../../modules/core/boot.nix
    ../../modules/core/nix.nix
    ../../modules/core/locale.nix
    ../../modules/core/networking.nix
    ../../modules/core/openssh.nix
    ../../modules/programs/shared.nix
    ../../modules/programs/dev.nix
    ../../modules/programs/gaming.nix
    ../../modules/programs/sunshine.nix
    ../../modules/hardware/nvidia.nix
    ../../modules/programs/openfortivpn.nix
    ../../modules/desktop/dms.nix
    ../../modules/desktop/stylix.nix
    ../../modules/hardware/audio.nix
    ../../modules/hardware/bluetooth.nix
    ../../modules/hardware/droidcam.nix
    ../../modules/hardware/logitech.nix
    ../../modules/hardware/printing.nix
    ../../modules/hardware/samsung-speaker-fix.nix
    ../../modules/hardware/samsung-webcam-fix.nix
  ];

  # Overlay do kernel CachyOS
  nixpkgs.overlays = [ inputs.nix-cachyos-kernel.overlays.pinned ];

  # Usuários deste host
  users.users.lucasp = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "video" "input" "docker" ];
    shell = pkgs.fish;
  };

  # Kernel params específicos desta máquina
  # i915.enable_psr=0 / enable_dc=0: workaround p/ bug do Meteor Lake em que o
  # PHY do eDP não recupera o refclk no resume ("PHY A failed to request refclk")
  # e o painel não acende às vezes ao abrir a tampa.
  boot.kernelParams = [
    "video=eDP-1:2880x1800@120"
    "i915.enable_psr=0"
    "i915.enable_dc=0"
    # enable_dpcd_backlight=3: painel AMOLED da Samsung (SDC) controla brilho via
    # DPCD/AUX com a interface HDR proprietária da Intel, não PWM. O VBT declara
    # PWM errado, então "auto" (-1) e "1" não resolvem — 3 força a interface Intel.
    # Se não resolver, testar 2 (força interface VESA padrão).
    "i915.enable_dpcd_backlight=3"
  ];
  boot.kernelModules = [ "i2c-dev" ];

  networking.hostName = "rodolucas";

  # Segredos cifrados (agenix). Descriptografados no boot com a chave SSH do
  # host e colocados direto onde os CLIs procuram, com dono lucasp.
  age.secrets = {
    aws-credentials = {
      file = ../../secrets/aws-credentials.age;
      path = "/home/lucasp/.aws/credentials";
      owner = "lucasp";
      group = "users";
      mode = "600";
    };
    oci-config = {
      file = ../../secrets/oci-config.age;
      path = "/home/lucasp/.oci/config";
      owner = "lucasp";
      group = "users";
      mode = "600";
    };
    oci-api-key = {
      file = ../../secrets/oci-api-key.age;
      path = "/home/lucasp/.oci/oci_api_key.pem";
      owner = "lucasp";
      group = "users";
      mode = "600";
    };
    # Credenciais SMB do NAS (lidas pelo root no boot pra montar via CIFS).
    nas-smb-creds.file = ../../secrets/nas-smb-creds.age;
  };

  # NAS D-Link DNS-320L (escritório) via CIFS/SMB1. Login vem do agenix.
  # automount + nofail: só monta no primeiro acesso e não trava o boot quando
  # você está fora da LAN do escritório (NAS inalcançável).
  environment.systemPackages = [ pkgs.cifs-utils ];
  fileSystems."/mnt/nas-vol1" = {
    device = "//10.1.1.251/Volume_1";
    fsType = "cifs";
    options = [
      "credentials=/run/agenix/nas-smb-creds"
      "vers=1.0"
      "sec=ntlmssp"
      "uid=1000"
      "gid=100"
      "iocharset=utf8"
      "file_mode=0664"
      "dir_mode=0775"
      "nofail"
      "_netdev"
      "x-systemd.automount"
      "x-systemd.idle-timeout=600"
      "x-systemd.mount-timeout=15"
    ];
  };

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
