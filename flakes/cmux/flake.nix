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

      cmuxSrc = pkgs.fetchFromGitHub {
        owner = "shuhei0866";
        repo = "cmux";
        rev = "linux-port";
        hash = "sha256-/VIDFE/nq3TyJrKCXwDxzbKnRJi6LgRZ8+ZOGMMMBAg=";
      };

      ghosttySrc = pkgs.fetchFromGitHub {
        owner = "ghostty-org";
        repo = "ghostty";
        rev = "v1.3.1";
        hash = "sha256-+ddMmUe9Jjkun4qqW8XFXVgwVZdVHsGWcQzndgIlBjQ=";
      };

      # Reuse nixpkgs' pre-fetched ghostty zig dependencies
      ghosttyDeps = pkgs.callPackage
        "${pkgs.path}/pkgs/by-name/gh/ghostty/deps.nix"
        { name = "ghostty-cache-1.3.1"; };

      # Combine cmux linux source with ghostty source tree
      src = pkgs.runCommand "cmux-src" {} ''
        cp -r ${cmuxSrc}/linux $out
        chmod -R u+w $out
        cp -r ${ghosttySrc} $out/ghostty
        chmod -R u+w $out/ghostty
      '';

      cmux = pkgs.rustPlatform.buildRustPackage {
        inherit pname version src;

        cargoHash = "sha256-/f7QHOPu8deeCvOjUabQPMqNJbjxuQj0DUAS7MAU9eE=";

        buildFeatures = [ "link-ghostty" ];

        nativeBuildInputs = with pkgs; [
          pkg-config
          wrapGAppsHook4
          zig_0_15
          pandoc
          ncurses  # for tic (terminfo compiler)
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
          # Ghostty build deps
          bzip2
          fontconfig
          freetype
          harfbuzz
          libGL
          libx11
          oniguruma
          glslang
          ncurses
          zlib
        ];

        # Prevent zig from being used as the Rust build system
        dontUseZigBuild = true;
        dontUseZigInstall = true;
        dontUseZigCheck = true;

        GHOSTTY_ZIG_DEPS = "${ghosttyDeps}";

        # Patch build.rs to inject nix-specific zig build flags
        postPatch = ''
          substituteInPlace ghostty-sys/build.rs \
            --replace-fail \
              '.arg("-Dapp-runtime=none") // none = libghostty (embedded runtime)' \
              '.arg("--system").arg(std::env::var("GHOSTTY_ZIG_DEPS").expect("GHOSTTY_ZIG_DEPS not set")).arg("-Dapp-runtime=none").arg("-fsys=glslang").arg("--search-prefix").arg("${pkgs.lib.getLib pkgs.glslang}").arg("-Dcpu=baseline").arg("-Dversion-string=1.3.1")'
        '';

        preBuild = ''
          export ZIG_GLOBAL_CACHE_DIR=$(mktemp -d)
          export ZIG_LOCAL_CACHE_DIR=$(mktemp -d)
        '';

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
