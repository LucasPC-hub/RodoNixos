{ config, pkgs, ... }:

let
  dmsConfigSrc = ../config/dms;
  dmsConfigDest = "${config.home.homeDirectory}/.config/niri/dms";
  flakeDmsPath = "/home/lucasp/RodoNixos/users/config/dms";
in
{
  home.packages = [
    (pkgs.writeShellScriptBin "dms-sync" ''
      src="${dmsConfigDest}"
      dest="${flakeDmsPath}"

      if [ ! -d "$src" ]; then
        echo "Diretório DMS não encontrado: $src"
        exit 1
      fi

      changed=false
      for f in "$src"/*.kdl; do
        name="$(basename "$f")"
        if [ ! -f "$dest/$name" ]; then
          echo ""
          echo "=== NOVO: $name ==="
          echo "[f] Ignorar"
          echo "[r] Copiar pro flake"
          printf "Escolha [f/r]: "
          read -r resp
          if [ "$resp" = "r" ] || [ "$resp" = "R" ]; then
            cp -v "$f" "$dest/$name"
          fi
          changed=true
        elif ! cmp -s "$f" "$dest/$name"; then
          echo ""
          echo "=== $name mudou ==="
          ${pkgs.diffutils}/bin/diff --color -u "$dest/$name" "$f" || true
          echo ""
          echo "[f] Manter versão do flake"
          echo "[r] Manter versão do runtime"
          printf "Escolha [f/r]: "
          read -r resp
          if [ "$resp" = "r" ] || [ "$resp" = "R" ]; then
            cp -v "$f" "$dest/$name"
            echo "Runtime copiado pro flake."
          else
            echo "Flake mantido."
          fi
          changed=true
        fi
      done

      if [ "$changed" = false ]; then
        echo "DMS configs em sync."
      fi
    '')
  ];

  home.activation.dmsConfig = config.lib.dag.entryAfter [ "writeBoundary" ] ''
    mkdir -p "${dmsConfigDest}"
    for f in ${dmsConfigSrc}/*.kdl; do
      dest="${dmsConfigDest}/$(basename "$f")"
      if [ ! -f "$dest" ] || ! cmp -s "$f" "$dest"; then
        cp "$f" "$dest"
        chmod 644 "$dest"
      fi
    done
  '';
}
