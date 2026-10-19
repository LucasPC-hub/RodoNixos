{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    # Ferramentas de uso geral (não específicas de projeto)
    gcc
    gh
    gnumake
    nixfmt
    docker-compose
    docker-buildx
    lazydocker

    # NOTA: toolchains de linguagem (Node/npm/pnpm/bun/yarn, Java, Python,
    # Rust, deps de build do Electrobun) NÃO ficam mais globais.
    # Use um devShell por projeto: flake.nix + `.envrc` (`use flake`),
    # carregado automaticamente pelo direnv/nix-direnv (users/shared.nix).

    # Rede — diagnóstico e testes
    nmap            # scan de portas/serviços
    mtr             # traceroute + ping contínuo
    traceroute
    dnsutils        # dig, nslookup
    whois
    tcpdump         # captura de pacotes (CLI)
    termshark       # tshark com TUI (wireshark no terminal)
    socat           # relay/proxy de sockets
    netcat-gnu      # nc
    iperf3          # benchmark de throughput TCP/UDP
    ethtool         # info/config de NIC
    bandwhich       # uso de banda por processo (TUI)
    gping           # ping com gráfico
    ipcalc          # cálculo de subnets
    httpie          # cliente HTTP amigável

    # API client
    bruno

    # Bun global (1.3.14 via overlay no flake.nix — nixpkgs ainda está em 1.3.13)
    bun

    # Coding agents (CLI)
    # oh-my-pi (omp) — wrapper bunx, versão fixa, sem build. Antes era @latest, que
    # resolvia pela rede a cada partida e travava o start em rede lenta. Para subir
    # de versão: trocar o número abaixo e rodar nixos-rebuild.
    # O core nativo roda via nix-ld.
    #
    # O bin do pacote é dist/cli.js com shebang `#!/usr/bin/env bun`, então quem
    # executa é o primeiro bun do PATH, e não o bunx apontado aqui. Devshells que
    # trazem bun próprio (o do vitrum trava em 1.3.13) sombreavam o nosso e
    # estouravam o check de versão do omp. Daí fixarmos o nosso bun na frente do
    # PATH: ${bun}/bin tem só bun e bunx, então node/pnpm do devshell continuam
    # intactos dentro da sessão do omp.
    (writeShellScriptBin "omp" ''
      export PATH=${bun}/bin:$PATH
      exec ${bun}/bin/bunx --bun @oh-my-pi/pi-coding-agent@18.4.9 "$@"
    '')

    # Navegador para automação por IA (omp browser / Puppeteer / Playwright).
    # Chromium do nixpkgs: roda nativo, sem depender do nix-ld.
    chromium
  ];

  # GSettings/dconf for GTK apps (file dialogs, etc.)
  programs.dconf.enable = true;

  # GSettings schema paths for GTK file dialogs (Electrobun, Tauri, etc.)
  environment.sessionVariables = {
    GSETTINGS_SCHEMA_DIR = "${pkgs.gsettings-desktop-schemas}/share/gsettings-schemas/${pkgs.gsettings-desktop-schemas.name}/glib-2.0/schemas";
  };
  environment.extraInit = ''
    export XDG_DATA_DIRS="$XDG_DATA_DIRS:${pkgs.gsettings-desktop-schemas}/share/gsettings-schemas/${pkgs.gsettings-desktop-schemas.name}:${pkgs.gtk3}/share/gsettings-schemas/${pkgs.gtk3.name}"
  '';
  # Puppeteer/Playwright usam o Chromium do sistema em vez do binário baixado.
  environment.variables = {
    PUPPETEER_EXECUTABLE_PATH = "${pkgs.chromium}/bin/chromium";
    CHROME_PATH = "${pkgs.chromium}/bin/chromium";
  };

  # Permitir binários dinâmicos (ex: electrobun, vscode extensions)
  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = with pkgs; [
    stdenv.cc.cc.lib
    gtk3
    webkitgtk_4_1
    glib
    cairo
    pango
    gdk-pixbuf
    libsoup_3
    at-spi2-atk
    harfbuzz
    libayatana-appindicator

    # Chromium baixado pelo Puppeteer/Playwright (o do omp) — headless shell
    nspr
    nss
    atk
    cups
    dbus
    expat
    libdrm
    libgbm
    mesa
    alsa-lib
    libxkbcommon
    libx11
    libxcomposite
    libxdamage
    libxext
    libxfixes
    libxrandr
    libxcb
    libxshmfence
    udev
  ];

  # adb precisa abrir o celular via USB; uaccess dá ACL ao usuário logado.
  services.udev.extraRules = ''
    SUBSYSTEM=="usb", ENV{ID_USB_INTERFACES}=="*:ff4201:*", TAG+="uaccess"
    SUBSYSTEM=="usb", ATTR{idVendor}=="04e8", TAG+="uaccess"
  '';

  virtualisation.docker = {
    enable = true;
    enableOnBoot = true;
    daemon.settings = {
      "exec-opts" = [ "native.cgroupdriver=systemd" ];
      "log-driver" = "json-file";
      "log-opts" = { "max-size" = "100m"; };
      "storage-driver" = "overlay2";
    };
  };
}
