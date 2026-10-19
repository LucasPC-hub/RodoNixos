# Perfil da laal: apps, Dolphin, scripts e ajustes do desktop. Importado pela
# laal (users/laal.nix) e por quem quer o mesmo ambiente (users/lucasbit.nix).
# Nada pessoal aqui (conta do git, contexto das IAs, aliases de projeto): isso
# fica no arquivo de cada usuário.
{ pkgs, config, ... }:

let
  jetbrains = import ./programs/jetbrains.nix { inherit pkgs; };

  # `pids`: lista processos com o app dono, RAM e pacote do Nix.
  pids = pkgs.writeShellApplication {
    name = "pids";
    runtimeInputs = with pkgs; [ procps gawk coreutils util-linux ];
    text = builtins.readFile ./config/scripts/pids.sh;
  };

  # Scripts dos widgets "desktopCommand" do DMS (área de trabalho). docker e
  # systemctl vêm do sistema, para bater com a versão do daemon.
  painelDocker = pkgs.writeShellApplication {
    name = "painel-docker";
    runtimeInputs = with pkgs; [ coreutils ];
    text = builtins.readFile ./config/scripts/painel-docker.sh;
  };
  painelServicos = pkgs.writeShellApplication {
    name = "painel-servicos";
    runtimeInputs = with pkgs; [ coreutils gawk gnused ];
    text = builtins.readFile ./config/scripts/painel-servicos.sh;
  };

  # OnlyOffice não enxerga fontes no NixOS: ele lê /usr/share/fonts dentro do
  # seu FHS/bwrap e não segue symlinks (bug upstream ONLYOFFICE/DocumentServer
  # #1859), e no Nix tudo é symlink. Copiamos as fontes de verdade (-L) para
  # um diretório e montamos ele em /usr/share/fonts. corefonts/vista-fonts são
  # as da Microsoft (Arial, Times, Calibri...): sem elas .docx/.xlsx abrem com
  # fonte trocada e marcadores quebrados.
  onlyofficeFontes = pkgs.runCommand "onlyoffice-fontes" { } ''
    mkdir -p $out
    for p in ${pkgs.lib.concatMapStringsSep " " (p: "${p}/share/fonts") (with pkgs; [
      corefonts
      vista-fonts
      liberation_ttf
      carlito
      caladea
      dejavu_fonts
      inter
      roboto
      noto-fonts-cjk-sans
      noto-fonts-color-emoji
    ])}; do
      cp -rL --no-preserve=mode "$p"/. $out/
    done
  '';
  onlyoffice = pkgs.buildFHSEnv (pkgs.onlyoffice-desktopeditors.passthru.args // {
    extraBwrapArgs = [ "--ro-bind" "${onlyofficeFontes}" "/usr/share/fonts" ];
  });

  # Dolphin no estilo do Dolphin do Matheus: estilo Darkly e miniaturas extras
  # (qtimageformats: jxl/heif/tiff etc.). Menos zoom: a sessão tem
  # QT_SCALE_FACTOR=1.5 (pro DMS), grande demais pro Dolphin. O vidro vem do
  # niri (opacity + blur na regra app-id org.kde.dolphin em niri-config.kdl)
  # e as cores do kdeglobals que o tema dinâmico do DMS escreve. Plataforma
  # "kde" (plasma-integration): com a gtk3 da sessão os ícones simbólicos do
  # tema escuro não eram recoloridos e ficavam pretos no fundo escuro.
  # QT_STYLE_OVERRIDE: a sessão força Breeze; aqui só o Dolphin usa Darkly.
  dolphin = pkgs.symlinkJoin {
    name = "dolphin-laal";
    paths = [ pkgs.kdePackages.dolphin ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/dolphin \
        --set QT_SCALE_FACTOR 1.15 \
        --set QT_QPA_PLATFORMTHEME kde \
        --set QT_STYLE_OVERRIDE Darkly \
        --prefix QT_PLUGIN_PATH : ${pkgs.lib.makeSearchPath "lib/qt-6/plugins" [
          pkgs.kdePackages.plasma-integration
          pkgs.darkly
          pkgs.kdePackages.qtimageformats
        ]}
      # O D-Bus (abrir pasta a partir de outros apps) chama o binário pelo
      # caminho absoluto; aponta pro wrapper.
      for f in $out/share/dbus-1/services/*.service; do
        cp --remove-destination "$(readlink -f "$f")" "$f"
        sed -i "s|${pkgs.kdePackages.dolphin}/bin/dolphin|$out/bin/dolphin|" "$f"
      done
    '';
  };

  # Ícone próprio pra um app: copia o .desktop do pacote trocando só o Icon=.
  # A cópia em ~/.local/share/applications tem prioridade sobre a do pacote.
  desktopComIcone = pacote: arquivo: icone: pkgs.runCommand "desktop-${arquivo}" { } ''
    sed 's|^Icon=.*|Icon=${icone}|' ${pacote}/share/applications/${arquivo} > $out
  '';
in
{
  imports = [
    ./shared.nix
  ];

  # yazi vem de users/shared.nix para todo mundo; a laal usa o Dolphin.
  programs.yazi.enable = pkgs.lib.mkForce false;

  # Pacotes do perfil
  home.packages = with pkgs; [
    obsidian
    pavucontrol
    vlc
    qbittorrent
    remmina
    onlyoffice
    zapzap
    dbeaver-bin
    (jetbrains.withJetbrainsWrapper pkgs.jetbrains.webstorm)
    (jetbrains.withJetbrainsWrapper pkgs.jetbrains.datagrip)
    zed-editor
    wl-mirror
    google-chrome

    # Explorador de arquivos: Dolphin + extras. Fora do Plasma ele roda
    # sozinho; os kio/thumbnailers são plugins carregados por ele.
    dolphin                              # wrapper com menos zoom (ver let acima)
    kdePackages.dolphin-plugins          # status do Git nos ícones, montar ISO
    kdePackages.ark                      # botão direito: Compactar / Extrair aqui
    kdePackages.kio-extras               # "Arquivos recentes", miniaturas, sftp/smb
    kdePackages.ffmpegthumbs             # miniaturas de vídeo
    kdePackages.kdegraphics-thumbnailers # miniaturas de PDF
    kdePackages.kimageformats            # webp, avif, heic, psd
    kdePackages.konsole                  # terminal embutido (F4)
    kdePackages.breeze-icons             # sem isso os ícones do Dolphin somem
    kdePackages.breeze                   # estilo Breeze (QT_STYLE_OVERRIDE abaixo)
    kdePackages.qtsvg
    kdePackages.filelight                # mapa de uso do disco
    kdePackages.baloo                    # busca por nome/conteúdo (serviço abaixo)
    kdePackages.okular                   # PDF, e prévia no painel de informações
    kdePackages.gwenview                 # imagens

    # Dependências dos plugins do DMS (eles chamam por nome no PATH):
    python3            # desktopCommand, dockerDashboard e colar no dmsfilemanager
    glib               # `gio trash` (lixeira) no dmsfilemanager
    xdg-terminal-exec  # botão de terminal do dmsfilemanager (abre o kitty, ver abaixo)
    translate-shell    # plugin dankTranslate
    xdg-user-dirs      # `xdg-user-dir` (pasta Downloads etc. nos plugins)
    kora-icon-theme    # ícones arredondados com volume (gradiente/sombra)
    nerd-fonts.jetbrains-mono # fonte mono do Matheus (DMS/terminal)
    noto-fonts         # fonte de interface do Matheus (Noto Sans)

    # Gerenciador de tarefas gráfico, agrupado por app (estilo Windows)
    mission-center
    # Abre cada app num grupo systemd com nome (app-<nome>-….scope); sem
    # isso o Mission Center não sabe a qual app cada processo pertence.
    # Usado como launchPrefix do DMS e nos atalhos do niri.
    app2unit
    btop
    tldr
    pids
    painelDocker
    painelServicos
  ];

  # `ajuda`/`comandos`: cola de comandos categorizada, gerada pelo
  # nix-command-catalog (mesmo catálogo do widget CommandShelf; ver
  # hosts/laal/dms-extras.nix). Fish autocarrega de functions/.
  xdg.configFile."fish/functions/ajuda.fish".source = ./config/fish/ajuda.fish;
  xdg.configFile."fish/functions/comandos.fish".source = ./config/fish/comandos.fish;

  # Dolphin igual ao do Matheus: caminho completo no título, barra de status
  # e miniaturas maiores. kwriteconfig6 só mexe nessas chaves; o resto do
  # dolphinrc continua sendo do próprio Dolphin.
  home.activation.dolphinrc = config.lib.dag.entryAfter [ "writeBoundary" ] ''
    rc="${config.xdg.configHome}/dolphinrc"
    k=${pkgs.kdePackages.kconfig}/bin/kwriteconfig6
    $k --file "$rc" --group General --key ShowFullPath true
    $k --file "$rc" --group General --key ShowStatusBar FullWidth
    $k --file "$rc" --group General --key TerminalApplication kitty
    $k --file "$rc" --group IconsMode --key PreviewSize 80
    $k --file "$rc" --group MainWindow --key MenuBar Disabled
  '';

  # Terminal padrão do xdg-terminal-exec.
  xdg.configFile."xdg-terminals.list".text = "kitty.desktop\n";

  # Ícones escolhidos pela laal pro Dolphin e o ZapZap.
  home.file.".local/share/applications/org.kde.dolphin.desktop".source =
    desktopComIcone pkgs.kdePackages.dolphin "org.kde.dolphin.desktop" ./config/icons/dolphin.png;
  home.file.".local/share/applications/com.rtosta.zapzap.desktop".source =
    desktopComIcone pkgs.zapzap "com.rtosta.zapzap.desktop" ./config/icons/zapzap.png;

  # Cedilha (ç/Ç) com dead_acute + c. No us-intl o padrão do xkb é
  # dead_acute + c = ć (acento agudo no c, uso eslavo). Esta regra de Compose
  # sobrescreve pro comportamento brasileiro. O `include "%L"` preserva todas
  # as outras composições do locale.
  home.file.".XCompose".text = ''
    include "%L"
    <dead_acute> <c> : "ç" U00E7
    <dead_acute> <C> : "Ç" U00C7
  '';

  # Ao abrir o kitty: fastfetch com uma imagem aleatória de ~/Pictures/fastfetch.
  # Só na primeira shell da janela: __FASTFETCH_SHOWN é exportada, então fish
  # aninhado, nsh/nix-shell e terminais de IDE (fora do kitty) não repetem.
  # Para adicionar imagens é só jogar na pasta (jpg, png, webp), sem fkr.
  programs.fish.interactiveShellInit = ''
    if set -q KITTY_WINDOW_ID; and not set -q __FASTFETCH_SHOWN; and not set -q IN_NIX_SHELL
      set -gx __FASTFETCH_SHOWN 1
      set -l imagens ~/Pictures/fastfetch/*.{jpg,jpeg,png,webp}
      if set -q imagens[1]
        # --pipe false: no início da shell o fastfetch às vezes acha que está
        # num pipe e troca a imagem pelo logo de texto. --disable-linewrap:
        # linha longa não quebra e não "vaza" para o lado da imagem.
        fastfetch --pipe false --disable-linewrap --kitty (random choice $imagens) --logo-width 30
      else
        fastfetch
      end
    end
  '';

  home.pointerCursor = {
    enable = true;
    gtk.enable = true;
    x11.enable = true;
    package = pkgs.adwaita-icon-theme;
    name = "Adwaita";
    size = 56;
  };

  home.sessionVariables = {
    EDITOR = "vim";
    QT_QPA_PLATFORMTHEME = "gtk3";
    # Dolphin, Okular etc. com o visual do KDE em vez do estilo cru do Qt.
    QT_STYLE_OVERRIDE = "Breeze";
    TERMINAL = "kitty";
    BROWSER = "zen-beta";
    FILES = "dolphin";
    NIXOS_OZONE_WL = "1";
  };

  # Sem um applications.menu (fora do Plasma) o "Abrir com" do Dolphin vem
  # vazio. Menu mínimo que inclui todo .desktop instalado.
  xdg.configFile."menus/applications.menu".text = ''
    <!DOCTYPE Menu PUBLIC "-//freedesktop//DTD Menu 1.0//EN"
     "http://www.freedesktop.org/standards/menu-spec/1.0/menu.dtd">
    <Menu>
      <Name>Applications</Name>
      <DefaultAppDirs/>
      <DefaultDirectoryDirs/>
      <Include><All/></Include>
    </Menu>
  '';

  # Indexador do baloo (busca do Dolphin). No Plasma ele sobe pelo autostart
  # do KDE; no niri não, então vira serviço do usuário.
  systemd.user.services.baloo-file = {
    Unit.Description = "Indexador de arquivos do KDE (baloo)";
    Unit.PartOf = [ "graphical-session.target" ];
    Service.ExecStart = "${pkgs.kdePackages.baloo}/libexec/kf6/baloo_file";
    Service.Restart = "on-failure";
    Service.Nice = 19;
    Service.IOSchedulingClass = "idle";
    Install.WantedBy = [ "graphical-session.target" ];
  };

  # Ações extras no botão direito do Dolphin (KIO service menus). Precisam
  # ser executáveis, senão o Dolphin ignora.
  xdg.dataFile = builtins.mapAttrs
    (_: menu: {
      target = "kio/servicemenus/${menu.name}.desktop";
      executable = true;
      text = ''
        [Desktop Entry]
        Type=Service
        MimeType=${menu.mime}
        Actions=a
        X-KDE-Submenu=${menu.submenu or ""}

        [Desktop Action a]
        Name=${menu.label}
        Icon=${menu.icon}
        Exec=${menu.exec}
      '';
    })
    {
      copiarCaminho = {
        name = "copiar-caminho";
        mime = "application/octet-stream;inode/directory;";
        label = "Copiar caminho";
        icon = "edit-copy-path";
        exec = "${pkgs.writeShellScript "copiar-caminho" ''
          printf '%s\n' "$@" | ${pkgs.wl-clipboard}/bin/wl-copy -n
        ''} %F";
      };
      abrirZed = {
        name = "abrir-no-zed";
        mime = "application/octet-stream;inode/directory;";
        label = "Abrir no Zed";
        icon = "zed";
        exec = "${pkgs.zed-editor}/bin/zeditor %F";
      };
      abrirKitty = {
        name = "abrir-no-kitty";
        mime = "inode/directory;";
        label = "Abrir terminal (kitty) aqui";
        icon = "kitty";
        exec = "${pkgs.kitty}/bin/kitty --directory %f";
      };
      paraWebp = {
        name = "converter-webp";
        mime = "image/png;image/jpeg;image/gif;image/bmp;image/tiff;image/avif;image/heic;";
        label = "Converter para WebP";
        icon = "image-x-generic";
        submenu = "Converter imagem";
        exec = "${pkgs.writeShellScript "converter-webp" ''
          for f in "$@"; do ${pkgs.imagemagick}/bin/magick "$f" "''${f%.*}.webp"; done
        ''} %F";
      };
      paraPng = {
        name = "converter-png";
        mime = "image/webp;image/jpeg;image/gif;image/bmp;image/tiff;image/avif;image/heic;";
        label = "Converter para PNG";
        icon = "image-x-generic";
        submenu = "Converter imagem";
        exec = "${pkgs.writeShellScript "converter-png" ''
          for f in "$@"; do ${pkgs.imagemagick}/bin/magick "$f" "''${f%.*}.png"; done
        ''} %F";
      };
      sha256 = {
        name = "sha256";
        mime = "application/octet-stream;";
        label = "Calcular SHA-256 (copia)";
        icon = "document-encrypted";
        exec = "${pkgs.writeShellScript "sha256-arquivo" ''
          h=$(${pkgs.coreutils}/bin/sha256sum "$1" | ${pkgs.coreutils}/bin/cut -d' ' -f1)
          printf '%s' "$h" | ${pkgs.wl-clipboard}/bin/wl-copy
          ${pkgs.libnotify}/bin/notify-send "SHA-256 copiado" "$(basename "$1"): $h"
        ''} %f";
      };
    };
}
