{ config, pkgs, ... }:

# DankBar da laal (users/config/dms-shell): configurações do DMS, dos plugins,
# tema, logo do launcher e papel de parede. Tema, logo e wallpaper ficam
# ligados ao repo; settings.json, plugin_settings.json e o wallpaper do
# session.json são gravados UMA vez (o DMS reescreve esses arquivos quando a
# pessoa muda algo na tela e o fkr não pode desfazer isso). Pra aplicar de
# novo: apagar ~/.config/DankMaterialShell/.dankbar-da-laal e rodar fkr.
#
# Pra atualizar a partir da máquina da laal: copiar settings.json e
# plugin_settings.json dela para users/config/dms-shell/, trocando /home/laal
# por @HOME@ (o logo do launcher aponta para @HOME@/.config/DankMaterialShell).
let
  src = ../config/dms-shell;
  cfg = "${config.xdg.configHome}/DankMaterialShell";
  state = "${config.xdg.stateHome}/DankMaterialShell";
  wallpaper = "${config.xdg.dataHome}/wallpapers/dankbar-laal.jpg";
in
{
  xdg.configFile."DankMaterialShell/themes".source = "${src}/themes";
  xdg.configFile."DankMaterialShell/arco-iris.png".source = "${src}/arco-iris.png";
  xdg.dataFile."wallpapers/dankbar-laal.jpg".source = "${src}/wallpaper.jpg";

  home.activation.dankbarLaal = config.lib.dag.entryAfter [ "writeBoundary" ] ''
    marca="${cfg}/.dankbar-da-laal"
    if [ ! -e "$marca" ]; then
      mkdir -p "${cfg}" "${state}"
      ${pkgs.gnused}/bin/sed 's|@HOME@|${config.home.homeDirectory}|g' ${src}/settings.json > "${cfg}/settings.json"
      install -m 644 ${src}/plugin_settings.json "${cfg}/plugin_settings.json"
      sessao="${state}/session.json"
      if [ -f "$sessao" ]; then
        ${pkgs.jq}/bin/jq --arg p "${wallpaper}" '.wallpaperPath = $p' "$sessao" > "$sessao.tmp"
        mv "$sessao.tmp" "$sessao"
      else
        printf '{"wallpaperPath":"%s"}\n' "${wallpaper}" > "$sessao"
      fi
      touch "$marca"
    fi
  '';
}
