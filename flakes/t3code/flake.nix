{
  description = "T3 Code - AI coding agent desktop GUI";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };

      pname = "t3code";
      version = "0.0.13";

      src = pkgs.fetchurl {
        url = "https://github.com/pingdotgg/t3code/releases/download/v${version}/T3-Code-${version}-x86_64.AppImage";
        hash = "sha256-oHKIh+aHsbGVHEoLLjItl6AbVRwvWVlZaIWyHKiekVc=";
      };

      t3code = pkgs.appimageTools.wrapType2 {
        inherit pname version src;

        extraInstallCommands =
          let
            appimageContents = pkgs.appimageTools.extractType2 { inherit pname version src; };
          in ''
            # Desktop entry & icon
            install -Dm444 ${appimageContents}/t3-code.desktop $out/share/applications/t3-code.desktop
            substituteInPlace $out/share/applications/t3-code.desktop \
              --replace-fail 'Exec=AppRun' 'Exec=t3code'
            cp -r ${appimageContents}/usr/share/icons $out/share/icons 2>/dev/null || true
          '';

        extraPkgs = p: with p; [
          alsa-lib
          at-spi2-atk
          cairo
          cups
          dbus
          expat
          gdk-pixbuf
          glib
          gtk3
          libdrm
          libxkbcommon
          mesa
          nspr
          nss
          pango
          libx11
          libxcomposite
          libxdamage
          libxext
          libxfixes
          libxrandr
          libxcb
        ];
      };
    in
    {
      packages.${system}.default = t3code;
    };
}
