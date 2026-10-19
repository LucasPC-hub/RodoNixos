{
  lib,
  stdenvNoCC,
  fetchurl,
  dpkg,
  buildFHSEnv,
}:

let
  # A OpenAI só publica a URL "latest": quando sair versão nova o hash quebra
  # o build ("hash mismatch"). Aí é atualizar version e hash aqui.
  version = "26.1007.71326";

  chatgpt-unwrapped = stdenvNoCC.mkDerivation {
    pname = "chatgpt-unwrapped";
    inherit version;

    src = fetchurl {
      url = "https://persistent.oaistatic.com/codex-app-prod/linux/deb/latest/chatgpt_amd64.deb";
      hash = "sha256-DgBrSTFxL1qQ1M0ElyxuC1M87c39srUZRtW5NnRx9VY=";
    };

    nativeBuildInputs = [ dpkg ];
    dontConfigure = true;
    dontBuild = true;

    unpackPhase = ''
      runHook preUnpack
      dpkg-deb -x "$src" .
      runHook postUnpack
    '';

    installPhase = ''
      runHook preInstall
      mkdir -p "$out"
      cp -r usr/lib usr/share "$out/"
      runHook postInstall
    '';
  };

in
buildFHSEnv {
  name = "chatgpt";

  targetPkgs = pkgs: [
    chatgpt-unwrapped
    pkgs.alsa-lib
    pkgs.at-spi2-atk
    pkgs.at-spi2-core
    pkgs.atk
    pkgs.cairo
    pkgs.cups
    pkgs.dbus
    pkgs.expat
    pkgs.glib
    pkgs.gdk-pixbuf
    pkgs.gtk3
    pkgs.libdrm
    pkgs.libgbm
    pkgs.libnotify
    pkgs.libsecret
    pkgs.libxkbcommon
    pkgs.mesa
    pkgs.nspr
    pkgs.nss
    pkgs.openssl
    pkgs.pango
    pkgs.systemd
    pkgs.tpm2-tss
    pkgs.xdg-utils
    pkgs.zlib
    pkgs.libx11
    pkgs.libxcomposite
    pkgs.libxdamage
    pkgs.libxext
    pkgs.libxfixes
    pkgs.libxrandr
    pkgs.libxcb
  ];

  runScript = "${chatgpt-unwrapped}/lib/chatgpt/codex-launcher";

  extraInstallCommands = ''
    mkdir -p "$out/share/applications" "$out/share/pixmaps"
    substitute "${chatgpt-unwrapped}/share/applications/chatgpt.desktop" \
      "$out/share/applications/chatgpt.desktop" \
      --replace-fail "Exec=chatgpt %U" "Exec=$out/bin/chatgpt %U"
    cp "${chatgpt-unwrapped}/share/pixmaps/chatgpt.png" "$out/share/pixmaps/chatgpt.png"
  '';

  meta = {
    description = "Official ChatGPT desktop app for Linux";
    homepage = "https://openai.com/codex/";
    license = lib.licenses.unfree;
    mainProgram = "chatgpt";
    platforms = [ "x86_64-linux" ];
  };
}
