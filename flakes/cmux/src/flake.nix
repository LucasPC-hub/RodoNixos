{
  description = "LCmux - terminal multiplexer for AI coding agents (fork of cmux by Manaflow)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };

      pname = "lcmux";
      version = "0.1.0";

      cmux = pkgs.rustPlatform.buildRustPackage {
        inherit pname version;
        src = ./.;

        cargoHash = "sha256-MXLXCEDNNKh04O91kgQfj/9H3b9d3MCt6+FoOcEYUCs=";

        nativeBuildInputs = with pkgs; [
          pkg-config
          wrapGAppsHook4
        ];

        buildInputs = with pkgs; [
          gtk4
          libadwaita
          glib
          gdk-pixbuf
          cairo
          pango
          graphene
          openssl
          vte-gtk4
          webkitgtk_6_0
          glib-networking
        ];

        postInstall = ''
          install -Dm644 data/lcmux.desktop $out/share/applications/lcmux.desktop
          install -Dm644 data/lcmux.svg $out/share/icons/hicolor/scalable/apps/lcmux.svg
        '';

        meta = with pkgs.lib; {
          description = "LCmux — terminal multiplexer for AI coding agents (fork of cmux by Manaflow)";
          homepage = "https://github.com/LucasPC-hub/lcmux";
          license = licenses.agpl3Only;
          platforms = [ "x86_64-linux" ];
        };
      };
    in
    {
      packages.${system}.default = cmux;
    };
}
