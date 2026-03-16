{ config, pkgs, ... }:

let
  homeDir = config.home.homeDirectory;
  niriDir = "${homeDir}/.config/niri";
  flakeBase = "/home/lucasp/RodoNixos/users/config";

  dmsConfigSrc = ../config/dms;
  niriConfigSrc = ../config/niri-config.kdl;

  syncFile = pkgs.writeShellScript "niri-sync-file" ''
    runtime="$1"
    flake="$2"
    name="$3"

    if [ ! -f "$flake" ]; then
      echo ""
      echo "=== NOVO: $name ==="
      echo "[f] Ignorar"
      echo "[r] Copiar pro flake"
      printf "Escolha [f/r]: "
      read -r resp
      if [ "$resp" = "r" ] || [ "$resp" = "R" ]; then
        cp -v "$runtime" "$flake"
      fi
      return 0
    fi

    if ! cmp -s "$runtime" "$flake"; then
      echo ""
      echo "=== $name mudou ==="
      ${pkgs.diffutils}/bin/diff --color -u "$flake" "$runtime" || true
      echo ""
      echo "[f] Manter versão do flake"
      echo "[r] Manter versão do runtime"
      printf "Escolha [f/r]: "
      read -r resp
      if [ "$resp" = "r" ] || [ "$resp" = "R" ]; then
        cp -v "$runtime" "$flake"
        echo "Runtime copiado pro flake."
      else
        echo "Flake mantido."
      fi
      return 0
    fi

    return 1
  '';
in
{
  home.packages = [
    (pkgs.writeShellScriptBin "niri-sync" ''
      changed=false

      # Sync config.kdl
      if [ -f "${niriDir}/config.kdl" ]; then
        ${syncFile} "${niriDir}/config.kdl" "${flakeBase}/niri-config.kdl" "config.kdl" && changed=true
      fi

      # Sync dms/*.kdl
      if [ -d "${niriDir}/dms" ]; then
        for f in "${niriDir}/dms"/*.kdl; do
          name="dms/$(basename "$f")"
          ${syncFile} "$f" "${flakeBase}/dms/$(basename "$f")" "$name" && changed=true
        done
      fi

      if [ "$changed" = false ]; then
        echo "Niri configs em sync."
      fi
    '')
  ];

  home.activation.niriConfig = config.lib.dag.entryAfter [ "writeBoundary" ] ''
    # Sync config.kdl
    dest="${niriDir}/config.kdl"
    if [ ! -f "$dest" ] || ! cmp -s "${niriConfigSrc}" "$dest"; then
      cp "${niriConfigSrc}" "$dest"
      chmod 644 "$dest"
    fi

    # Sync dms/*.kdl
    mkdir -p "${niriDir}/dms"
    for f in ${dmsConfigSrc}/*.kdl; do
      dest="${niriDir}/dms/$(basename "$f")"
      if [ ! -f "$dest" ] || ! cmp -s "$f" "$dest"; then
        cp "$f" "$dest"
        chmod 644 "$dest"
      fi
    done
  '';
}
