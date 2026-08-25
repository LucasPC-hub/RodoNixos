{ pkgs, ... }:

{
  # Driver VAAPI da Intel (iHD). Este laptop é híbrido: o niri renderiza na
  # iGPU Intel (Meteor Lake), e o eDP-1 é escaneado por ela. Logo o encode
  # TEM que ser na Intel — zero-copy, sem cruzar pra NVIDIA (era o que dava
  # as "linhas pretas"/Frame capture failed). Sem o iHD o Sunshine não acha
  # encoder de HW e cai no x264 software com a captura corrompida.
  hardware.graphics.extraPackages = [ pkgs.intel-media-driver ];

  # Sunshine = servidor de streaming (host). No outro dispositivo você usa
  # o Moonlight (cliente) pra conectar e ver/controlar esta tela.
  services.sunshine = {
    enable = true;
    autoStart = true;
    openFirewall = true;

    # Wayland precisa de captura KMS, que exige CAP_SYS_ADMIN.
    capSysAdmin = true;

    settings = {
      # UI web em https://localhost:47990.
      sunshine_name = "rodolucas";

      # Força o encoder VAAPI no render node da Intel (by-path é estável
      # entre boots, ao contrário de renderD12X).
      encoder = "vaapi";
      adapter_name = "/dev/dri/by-path/pci-0000:00:02.0-render";
    };
  };

  # libva precisa saber qual driver usar no processo do Sunshine (iHD = Intel).
  systemd.user.services.sunshine.environment.LIBVA_DRIVER_NAME = "iHD";

  # Captura: forçar KMS (grab direto do DRM), NÃO o grabber Wayland.
  # O niri (smithay) expõe zwlr_screencopy_v1+linux_dmabuf, então o Sunshine
  # escolhe o backend "Screencasting with Wayland's protocol" — mas o caminho
  # screencopy→dmabuf dele QUEBRA em runtime no niri: na primeira captura da
  # sessão real dá "Frame capture failed" e o processo CRASHA (core-dump),
  # então o Moonlight vê tela preta + erro de conexão -1. (O probe de encoder
  # no boot passa porque usa frame sintético; só a sessão real quebrava.)
  # KMS é o caminho recomendado p/ niri: independe de protocolo do compositor
  # e usa o CAP_SYS_ADMIN que já temos. O Sunshine só usa KMS quando
  # WAYLAND_DISPLAY NÃO está no ambiente — daí o UnsetEnvironment.
  systemd.user.services.sunshine.serviceConfig.UnsetEnvironment = "WAYLAND_DISPLAY";

  # Re-associação por mudança de regdom também derruba o stream: o iwlwifi sobe
  # num domínio regulatório restrito e, ao ver o country code BR no beacon do AP,
  # TROCA o regdom em runtime → recalcula canais (habilita 6GHz) → re-associa.
  # Esse religamento de ~1s mata o Moonlight (visto como burst de "sendmsg 101").
  # Fixando BR no boot não há "mudança" pra reagir — sem re-associação periódica.
  boot.extraModprobeConfig = ''
    options cfg80211 ieee80211_regdom=BR
  '';

  # Wi-Fi power save MATA o stream: com sinal excelente e sem deauth, o rádio
  # iwlwifi "cochila" entre pacotes e gera picos de latência/perda que derrubam
  # o UDP do Moonlight (e até sessões SSH ociosas). O parâmetro do módulo já vem
  # power_save=N, mas o NetworkManager religa em runtime (wifi.powersave=default).
  # Desliga de vez — este host é o servidor de streaming, latência > bateria.
  networking.networkmanager.wifi.powersave = false;

  environment.systemPackages = with pkgs; [ iw moonlight-qt ];
}
