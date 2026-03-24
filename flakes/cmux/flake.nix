{
  description = "cmux - terminal multiplexer for AI coding agents (Linux port)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };

      pname = "cmux";
      version = "0.1.0";

      src = pkgs.fetchFromGitHub {
        owner = "shuhei0866";
        repo = "cmux";
        rev = "linux-port";
        hash = "sha256-/VIDFE/nq3TyJrKCXwDxzbKnRJi6LgRZ8+ZOGMMMBAg=";
      };

      cmux = pkgs.rustPlatform.buildRustPackage {
        inherit pname version;
        src = "${src}/linux";

        useFetchCargoVendor = true;
        cargoHash = "sha256-/f7QHOPu8deeCvOjUabQPMqNJbjxuQj0DUAS7MAU9eE=";

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
        ];

        # Build without ghostty linking (stub mode)
        buildNoDefaultFeatures = true;

        meta = with pkgs.lib; {
          description = "Terminal multiplexer for AI coding agents (Linux port)";
          homepage = "https://github.com/manaflow-ai/cmux";
          license = licenses.agpl3Only;
          platforms = [ "x86_64-linux" ];
        };
      };
    in
    {
      packages.${system}.default = cmux;
    };
}
