// Catálogo das ferramentas do hub, usado pela aba Ferramentas do NordHub e
// pela setinha da bandeja (BandejaOculta importa "../NordHub/Ferramentas.js").
//
// kind: "plugin" (IPC de um plugin carregado), "widget" (host na barra, pode
// estar desligado: o DMS carrega sob demanda no `widget toggle`), "desktop"
// (instância de widget de desktop), "native" (sempre presente no DMS).
.pragma library

var lista = [
        {
            "name": "Calculadora",
            "desc": "Abre o launcher em modo cálculo",
            "icon": "calculate",
            "category": "util",
            "kind": "plugin",
            "target": "calculator",
            "ipc": ["launcher", "openQuery", "= "],
            "keywords": "calculator conta matematica ="
        },
        {
            "name": "Emoji",
            "desc": "Seletor de emojis",
            "icon": "mood",
            "category": "util",
            "kind": "plugin",
            "target": "emojiPicker",
            "ipc": ["emojiPicker", "toggle"],
            "keywords": "emoji picker"
        },
        {
            "name": "Kaomoji",
            "desc": "Busca kaomoji no launcher",
            "icon": "sentiment_very_satisfied",
            "category": "util",
            "kind": "plugin",
            "target": "kaomojiPicker",
            "ipc": ["launcher", "openQuery", "kj "],
            "keywords": "kaomoji kj"
        },
        {
            "name": "Clipboard+",
            "desc": "Histórico, notas e tarefas",
            "icon": "content_paste",
            "category": "util",
            "kind": "widget",
            "target": "clipboardPlus",
            "ipc": ["widget", "toggle", "clipboardPlus"],
            "keywords": "clipboard area de transferencia notas todo"
        },
        {
            "name": "OCR",
            "desc": "Texto de imagens copiadas",
            "icon": "document_scanner",
            "category": "util",
            "kind": "widget",
            "target": "ocrScanner",
            "ipc": ["widget", "toggle", "ocrScanner"],
            "keywords": "ocr scanner tesseract texto"
        },
        {
            "name": "Downloader",
            "desc": "Baixar mídia com yt-dlp",
            "icon": "download",
            "category": "util",
            "kind": "widget",
            "target": "mediaDownloader",
            "ipc": ["widget", "toggle", "mediaDownloader"],
            "keywords": "media downloader youtube yt-dlp video audio"
        },
        {
            "name": "Bitwarden",
            "desc": "Cofre; login e desbloqueio manuais",
            "icon": "key",
            "category": "util",
            "kind": "plugin",
            "target": "bitwarden",
            "ipc": ["bitwarden", "toggle"],
            "keywords": "bitwarden senha password cofre vault"
        },
        {
            "name": "Mídia+",
            "desc": "Player com capa e seekbar",
            "icon": "music_note",
            "category": "media",
            "kind": "widget",
            "target": "mediaControlPlus",
            "ipc": ["widget", "toggle", "mediaControlPlus"],
            "keywords": "media midia player musica mpris"
        },
        {
            "name": "Áudio",
            "desc": "Volume, microfone e dispositivos",
            "icon": "volume_up",
            "category": "media",
            "kind": "widget",
            "target": "simpleAudioControl",
            "ipc": ["widget", "toggle", "simpleAudioControl"],
            "keywords": "audio som volume saida microfone"
        },
        {
            "name": "Som ambiente",
            "desc": "Nada toca até você escolher",
            "icon": "forest",
            "category": "media",
            "kind": "widget",
            "target": "ambientSound",
            "ipc": ["widget", "toggle", "ambientSound"],
            "keywords": "ambient som ambiente chuva foco"
        },
        {
            "name": "Espelho",
            "desc": "Câmera só ativa ao abrir; nada automático",
            "icon": "photo_camera",
            "category": "media",
            "kind": "widget",
            "target": "handMirror",
            "ipc": ["widget", "toggle", "handMirror"],
            "keywords": "camera espelho mirror webcam"
        },
        {
            "name": "Respiração",
            "desc": "Exercícios guiados",
            "icon": "air",
            "category": "wellbeing",
            "kind": "widget",
            "target": "breathing",
            "ipc": ["widget", "toggle", "breathing"],
            "keywords": "breathing respiracao relaxar"
        },
        {
            "name": "Pausas",
            "desc": "Lembretes de descanso",
            "icon": "self_improvement",
            "category": "wellbeing",
            "kind": "widget",
            "target": "takeABreak",
            "ipc": ["widget", "toggle", "takeABreak"],
            "keywords": "take a break pausa descanso"
        },
        {
            "name": "Timer",
            "desc": "Contagem regressiva",
            "icon": "timer",
            "category": "wellbeing",
            "kind": "widget",
            "target": "timer",
            "ipc": ["widget", "toggle", "timer"],
            "keywords": "timer cronometro contagem"
        },
        {
            "name": "Docker",
            "desc": "Containers e compose",
            "icon": "deployed_code",
            "category": "system",
            "kind": "widget",
            "target": "dockerManager",
            "ipc": ["widget", "toggle", "dockerManager"],
            "keywords": "docker container compose"
        },
        {
            "name": "IP",
            "desc": "Consulta pública só manual",
            "icon": "public",
            "category": "system",
            "kind": "widget",
            "target": "ipIndicator",
            "ipc": ["widget", "toggle", "ipIndicator"],
            "keywords": "ip rede network endereco"
        },
        {
            "name": "NetBird",
            "desc": "Status e peers; sem conectar ao abrir",
            "icon": "vpn_lock",
            "category": "system",
            "kind": "widget",
            "target": "netbirdStatus",
            "ipc": ["widget", "toggle", "netbirdStatus"],
            "keywords": "netbird vpn peers rede status"
        },
        {
            "name": "Lutris",
            "desc": "Jogos instalados",
            "icon": "sports_esports",
            "category": "system",
            "kind": "widget",
            "target": "lutrisLauncher",
            "ipc": ["widget", "toggle", "lutrisLauncher"],
            "keywords": "lutris jogos games"
        },
        {
            "name": "Monitores",
            "desc": "Perfis de tela do Niri",
            "icon": "monitor",
            "category": "system",
            "kind": "plugin",
            "target": "niriDS",
            "ipc": ["niriDS", "toggle"],
            "keywords": "niri display monitor tela"
        },
        {
            "name": "Wallpapers",
            "desc": "Carrossel de papéis de parede",
            "icon": "wallpaper",
            "category": "system",
            "kind": "plugin",
            "target": "wallpaperCarousel",
            "ipc": ["wallpaperCarousel", "toggle"],
            "keywords": "wallpaper papel de parede carousel"
        },
        {
            "name": "Plugins",
            "desc": "Configurações dos plugins",
            "icon": "extension",
            "category": "system",
            "kind": "native",
            "target": "",
            "ipc": ["settings", "openWith", "plugins"],
            "keywords": "plugins configuracoes settings"
        },
        {
            "name": "Grupos desktop",
            "desc": "Alternar grupos de widgets",
            "icon": "widgets",
            "category": "desktop",
            "kind": "widget",
            "target": "desktopWidgetToggle",
            "ipc": ["widget", "toggle", "desktopWidgetToggle"],
            "keywords": "desktop widget grupos"
        },
        {
            "name": "Arquivos",
            "desc": "Mostrar/ocultar no desktop",
            "icon": "folder_open",
            "category": "desktop",
            "kind": "desktop",
            "target": "m_arquivos",
            "ipc": ["desktopWidget", "toggleEnabled", "m_arquivos"],
            "keywords": "arquivos files desktop"
        },
        {
            "name": "GitHub heatmap",
            "desc": "Mostrar/ocultar no desktop",
            "icon": "grid_view",
            "category": "desktop",
            "kind": "desktop",
            "target": "m_github",
            "ipc": ["desktopWidget", "toggleEnabled", "m_github"],
            "keywords": "github heatmap contribuicoes desktop"
        },
        {
            "name": "EnderPulse",
            "desc": "Mostrar/ocultar no desktop",
            "icon": "graphic_eq",
            "category": "desktop",
            "kind": "desktop",
            "target": "m_pulse",
            "ipc": ["desktopWidget", "toggleEnabled", "m_pulse"],
            "keywords": "enderpulse visualizer audio desktop"
        },
        {
            "name": "Calendário P5",
            "desc": "Mostrar/ocultar no desktop",
            "icon": "calendar_month",
            "category": "desktop",
            "kind": "desktop",
            "target": "m_persona",
            "ipc": ["desktopWidget", "toggleEnabled", "m_persona"],
            "keywords": "persona calendario desktop"
        }
];

// "" quando a ferramenta pode ser aberta; senão, o motivo. `s` traz os
// singletons do DMS: { BarWidgetService, PluginService, SettingsData }.
function motivoIndisponivel(tool, s) {
    const temHost = id => s.BarWidgetService.hasWidget(id) || hostsNaBarra(s.SettingsData.barConfigs)[id] === true;
    if (tool.requiredWidget && !temHost(tool.requiredWidget))
        return "Host da barra inativo";
    switch (tool.kind) {
    case "plugin":
        return s.PluginService.isPluginLoaded(tool.target) ? "" : "Plugin desativado";
    case "widget":
        if (!s.PluginService.isPluginLoaded(tool.target) && !s.BarWidgetService.hasWidget(tool.target))
            return "Plugin desativado";
        return temHost(tool.target) ? "" : "Host da barra inativo";
    case "desktop":
        return s.SettingsData.getDesktopWidgetInstance(tool.target) ? "" : "Instância não configurada";
    default:
        return "";
    }
}

// Ids de widgets que têm host em alguma barra ligada, mesmo com o widget
// desligado (enabled: false). O `dms ipc call widget toggle` carrega esses
// hosts sob demanda, então eles contam como disponíveis.
function hostsNaBarra(barConfigs) {
    const ids = {};
    for (const bar of barConfigs || []) {
        if (bar.enabled === false)
            continue;
        for (const secao of [bar.leftWidgets, bar.centerWidgets, bar.rightWidgets])
            for (const w of secao || [])
                ids[typeof w === "string" ? w : w.id] = true;
    }
    return ids;
}
