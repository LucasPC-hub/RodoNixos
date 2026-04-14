{ config, pkgs, ... }:

let
  homeDir = config.home.homeDirectory;
  niriDir = "${homeDir}/.config/niri";
  flakeBase = "${homeDir}/RodoNixos/users/config";

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
      exit 0
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
      exit 0
    fi

    exit 1
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
}
