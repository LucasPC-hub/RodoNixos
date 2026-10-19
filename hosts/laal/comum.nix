{ pkgs, ... }:

# Parte do host da laal que vale pra qualquer máquina com o mesmo ambiente
# (hoje: laal e rodolucasbit). O que é do hardware ou só da laal (nvidia,
# tela 165 Hz, tailscale, DLNA, manutenção) fica no default.nix de cada host.
{
  imports = [
    ./dms-extras.nix

    ../../modules/core/boot.nix
    ../../modules/core/nix.nix
    ../../modules/core/locale.nix
    ../../modules/core/openssh.nix
    ../../modules/programs/shared.nix
    ../../modules/programs/dev.nix
    ../../modules/desktop/dms.nix
    ../../modules/desktop/stylix.nix
    ../../modules/hardware/audio.nix
    ../../modules/hardware/bluetooth.nix
    ../../modules/hardware/printing.nix
    ../../modules/programs/openfortivpn.nix
  ];

  # Networking — inline pra não puxar o extraHosts do lucasp
  networking.networkmanager.enable = true;
  networking.firewall.enable = true;

  # Plugins do Dolphin que precisam do sistema: o kio-admin ("Abrir como
  # administrador") é um serviço D-Bus de sistema com regra do polkit, e o
  # kio-fuse (pastas remotas abertas como pasta normal) é ativado pelo D-Bus
  # da sessão. Em home.packages o D-Bus não acha nenhum dos dois.
  environment.systemPackages = [ pkgs.kdePackages.kio-admin pkgs.kdePackages.kio-fuse ];
  services.dbus.packages = [ pkgs.kdePackages.kio-admin pkgs.kdePackages.kio-fuse ];

  # DMS travando em loop depois da suspensão. Ao voltar, o backend PipeWire do
  # QtMultimedia (usado pelos sons do DMS) fica com um socket fechado e o
  # quickshell entra em loop infinito de "QSocketNotifier: Invalid socket ...
  # disabling", gastando CPU e RAM (2,5 milhões de linhas no journal em
  # 30/09/2026, até reiniciar o PC). Bug do Quickshell/Qt 6.11, ainda sem
  # correção no upstream. O backend PulseAudio passa pelo pipewire-pulse e
  # não tem esse problema.
  systemd.user.services.dms = {
    environment.QT_AUDIO_BACKEND = "pulseaudio";
    # O plugin dmsfilemanager importa Qt5Compat.GraphicalEffects, que não vem
    # no quickshell. Mesmo qtbase (6.11.2) do quickshell, então é compatível.
    environment.QML_IMPORT_PATH = "${pkgs.kdePackages.qt5compat}/lib/qt-6/qml";
    # Rede de segurança: se ainda assim disparar, o systemd mata o DMS ao
    # passar de 2 GiB (normal: ~0,5-0,8 GiB) e o Restart=on-failure da unit
    # sobe ele de novo em ~1 s.
    serviceConfig.MemoryMax = "2G";
  };

  # Notebook: bateria e energia
  services.upower.enable = true;
  services.power-profiles-daemon.enable = true;

  # Montar dispositivos (MTP, USB) + thumbnails no file manager
  services.gvfs.enable = true;
  services.tumbler.enable = true;

  # Fonts (mesmo set do rodolucas)
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
}
