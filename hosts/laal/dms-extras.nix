# Plugins do DMS trazidos do repo do Matheus (Matheuscara/dotfiles, 15/10/2026)
# e o que eles precisam pra funcionar: dependências, ChatGPT, helpers do
# Bitwarden e o catálogo de comandos (CommandShelf + `ajuda` do fish).
#
# Os plugins daqui vão em /etc/xdg/quickshell/dms-plugins (sistema). Os que a
# laal instalou pela loja do DMS continuam em ~/.config/DankMaterialShell/plugins;
# não pode haver o mesmo id nos dois lugares, por isso só entram aqui os que ela
# não tinha (Bitwarden e DmsFileManager substituem os dela).
{ pkgs, ... }:

let
  pluginDir = ./dms-plugins;
  vendored = builtins.listToAttrs (
    map (name: {
      inherit name;
      value.src = builtins.path {
        path = pluginDir + "/${name}";
        name = "dms-plugin-${name}";
      };
    }) (builtins.attrNames (builtins.readDir pluginDir))
  );

  # Pacote de plugins do hthienloc: fonte dos sons ambientes e do calendário.
  htlPlugins = pkgs.fetchzip {
    url = "https://codeload.github.com/hthienloc/dms-plugins/tar.gz/bf57081d6ad6dff5c4f55d4ca2c80b5c4a91b642";
    extension = "tar.gz";
    hash = "sha256-JFaqdZ4f/Tsetz5aE8jkCnzcCc4Z+F9ETtYDoYQbiOY=";
  };

  githubHeatmap = pkgs.applyPatches {
    name = "dms-github-heatmap-2.1.0";
    src = pkgs.fetchFromGitHub {
      owner = "maxlen727";
      repo = "DMS-GitHub_HeatMap_Plus";
      rev = "0ad3146b8f602be957078c3423e8ae8e4c63756a";
      hash = "sha256-1A7bw/NHEyvj7ngCnLAQzTBiwX/oC7J4qaM/sylsb2o=";
    };
    patches = [ ./patches/github-heatmap-dms146.patch ];
  };

  fileManager = pkgs.applyPatches {
    name = "dms-filemanager-1.0.7";
    src = pkgs.fetchFromGitHub {
      owner = "suruibin";
      repo = "dms-filemanager";
      rev = "712154f3eb5dae789ce03f0700488163928395fa";
      hash = "sha256-zZo626so60kUB2RMwD5FKBXzK59kyUtUn7NXQblB6OU=";
    };
    patches = [ ./patches/dms-filemanager-dms146.patch ];
    postPatch = ''
      substituteInPlace appimage_icon.py \
        --replace-fail 'UNSQUASHFS = "unsquashfs"' 'UNSQUASHFS = "${pkgs.squashfsTools}/bin/unsquashfs"'
    '';
  };

  personaCalendar = pkgs.applyPatches {
    name = "dms-persona5-calendar-1.0.0";
    src = "${htlPlugins}/persona5Calendar";
    patches = [ ./patches/persona5-calendar-dms146.patch ];
    postPatch = ''
      cp ${htlPlugins}/LICENSE LICENSE
    '';
  };

  # Espelho: o original só desligava a câmera quando o conteúdo do popout era
  # destruído, e o DMS mantém esse conteúdo carregado depois de fechar.
  handMirror = pkgs.applyPatches {
    name = "dms-hand-mirror-1.1.1";
    src = "${htlPlugins}/handMirror";
    patches = [ ./patches/hand-mirror-camera.patch ];
  };

  plugins = vendored // {
    GitHubHeatmapPlus.src = githubHeatmap;
    DmsFileManager.src = fileManager;
    HTL-persona5Calendar.src = personaCalendar;
    HTL-kaomojiPicker.src = "${htlPlugins}/kaomojiPicker";
    HTL-handMirror.src = handMirror;
  };

  # Cache de QML por geração das fontes: troca de plugin/patch não reaproveita
  # bytecode compilado da versão anterior.
  qmlCacheGeneration = builtins.substring 0 16 (
    builtins.hashString "sha256" (
      builtins.concatStringsSep ":" (map (p: toString p.src) (builtins.attrValues plugins))
    )
  );

  bitwardenHelpers = pkgs.callPackage ./pkgs/qs-bitwarden-helpers { };
  chatgpt = pkgs.callPackage ./pkgs/chatgpt { };

  # Catálogo de comandos: fonte única do `ajuda` (fish) e do widget CommandShelf.
  commandCatalog = pkgs.writeShellApplication {
    name = "nix-command-catalog";
    runtimeInputs = [ pkgs.python3 ];
    text = ''
      exec python3 ${./dms-plugins/CommandShelf/commands.py} "$@"
    '';
  };
in
{
  programs.dms-shell.plugins = plugins;

  environment.etc = {
    "xdg/quickshell/dms-plugin-assets/ambient-sounds".source = "${htlPlugins}/ambientSound/sounds";
  };

  systemd.user.services.dms.environment.QML_DISK_CACHE_PATH =
    "%C/DankMaterialShell/qml-${qmlCacheGeneration}";

  environment.systemPackages = [
    bitwardenHelpers
    chatgpt
    commandCatalog
    pkgs.bitwarden-cli
    pkgs.libsecret
    pkgs.pinentry-qt
    pkgs.libargon2
    pkgs.openssl
    pkgs.dgop # NordHub (gráficos de desempenho)
    pkgs.libnotify
    pkgs.libqalculate
    pkgs.jq
    pkgs.mpv # sons ambientes
    pkgs.socat
    (pkgs.tesseract.override { enableLanguages = [ "eng" "por" ]; }) # OCR
    pkgs.yt-dlp # download de mídia
    pkgs.cava # EnderPulse
    pkgs.pulseaudio # pactl (controle de áudio)
    pkgs.file
    pkgs.librsvg
    pkgs.poppler-utils
    pkgs.squashfsTools
    pkgs.wtype
  ];
}
