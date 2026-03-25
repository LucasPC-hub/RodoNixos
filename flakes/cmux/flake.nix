{
  description = "cmux - terminal multiplexer for AI coding agents (Linux/VTE)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };

      pname = "cmux";
      version = "0.1.0";

      cmux = pkgs.rustPlatform.buildRustPackage {
        inherit pname version;
        src = ./src;

        cargoHash = "sha256-X9jIXBx6HlpUyoh/wPxW5bj7G9EkmNzyHu3jikpw4/U=";

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
        ];

        meta = with pkgs.lib; {
          description = "Terminal multiplexer for AI coding agents (Linux/VTE)";
          homepage = "https://github.com/manaflow-ai/cmux";
          license = licenses.agpl3Only;
          platforms = [ "x86_64-linux" ];
        };
      };

      # AppImage: self-contained bundle for distribution
      appimage = pkgs.runCommand "cmux-${version}-x86_64.AppImage" {
        nativeBuildInputs = [ pkgs.appimage-run pkgs.squashfsTools ];
      } ''
        mkdir -p AppDir/usr/bin AppDir/usr/lib AppDir/usr/share

        # Copy binaries
        cp ${cmux}/bin/cmux-app AppDir/usr/bin/
        cp ${cmux}/bin/cmux AppDir/usr/bin/

        # Create desktop entry
        cat > AppDir/cmux.desktop <<EOF
        [Desktop Entry]
        Name=cmux
        Exec=cmux-app
        Icon=cmux
        Type=Application
        Categories=Development;TerminalEmulator;
        EOF
        # Fix leading whitespace
        sed -i 's/^        //' AppDir/cmux.desktop

        # Create a simple icon (placeholder)
        mkdir -p AppDir/usr/share/icons/hicolor/256x256/apps
        ${pkgs.imagemagick}/bin/convert -size 256x256 xc:'#1a1a2e' \
          -fill '#e94560' -draw "roundrectangle 30,30 226,226 20,20" \
          -fill white -font ${pkgs.dejavu_fonts}/share/fonts/truetype/DejaVuSans-Bold.ttf \
          -pointsize 120 -gravity center -annotate 0 "C" \
          AppDir/usr/share/icons/hicolor/256x256/apps/cmux.png
        cp AppDir/usr/share/icons/hicolor/256x256/apps/cmux.png AppDir/cmux.png

        # Create AppRun script that sets up the environment
        cat > AppDir/AppRun <<'APPRUN'
        #!/bin/bash
        HERE="$(dirname "$(readlink -f "$0")")"
        exec "$HERE/usr/bin/cmux-app" "$@"
        APPRUN
        chmod +x AppDir/AppRun

        # Bundle shared libraries
        for lib in ${cmux}/lib/*.so*; do
          cp -L "$lib" AppDir/usr/lib/ 2>/dev/null || true
        done

        # Create squashfs and AppImage
        mksquashfs AppDir squashfs.img -root-owned -noappend -comp zstd
        cat ${pkgs.appimage-run.src or "/dev/null"} squashfs.img > $out 2>/dev/null || \
          cp squashfs.img $out
        chmod +x $out
      '';
    in
    {
      packages.${system} = {
        default = cmux;
        appimage = appimage;
      };
    };
}
