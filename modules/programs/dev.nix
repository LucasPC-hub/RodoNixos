{ pkgs, ... }:

let
  withNvidiaOffload = pkg: pkgs.symlinkJoin {
    name = "${pkg.pname or pkg.name}-nvidia";
    paths = [ pkg ];
    buildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      for bin in $out/bin/*; do
        wrapProgram "$bin" \
          --set __NV_PRIME_RENDER_OFFLOAD 1 \
          --set __GLX_VENDOR_LIBRARY_NAME nvidia \
          --set __VK_LAYER_NV_optimus NVIDIA_only
      done
    '';
  };
in
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
    # oh-my-pi (omp) — wrapper bunx: sempre a última versão do npm, sem build.
    # O core nativo roda via nix-ld.
    (writeShellScriptBin "omp" ''
      exec ${bun}/bin/bunx --bun @oh-my-pi/pi-coding-agent@latest "$@"
    '')

    # IDEs
    (withNvidiaOffload jetbrains.datagrip)
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
  ];

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
