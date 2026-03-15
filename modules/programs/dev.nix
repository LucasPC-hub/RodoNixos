{ pkgs, ... }:

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

    # Rust
    rustup
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
