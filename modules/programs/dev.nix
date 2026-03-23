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
    # Ferramentas
    gcc
    gh
    gnumake
    nixfmt
    docker-compose
    docker-buildx
    lazydocker

    # Node
    nodejs_22
    pnpm
    bun
    yarn

    # Java
    jdk21
    maven
    gradle

    # Python
    python312
    python312Packages.pip

    # Electrobun
    cmake
    pkg-config
    gtk3
    webkitgtk_4_1
    libayatana-appindicator
    librsvg

    # Rust
    rustup

    # API client
    bruno

    # IDEs
    (withNvidiaOffload jetbrains.datagrip)
  ];

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
