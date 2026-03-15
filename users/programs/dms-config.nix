{ config, pkgs, ... }:

let
  dmsConfigSrc = ../config/dms;
  dmsConfigDest = "${config.home.homeDirectory}/.config/niri/dms";
  flakeDmsPath = "/home/lucasp/RodoNixos/users/config/dms";
in
{
  # Script pra sincronizar mudanças do DMS de volta pro flake
  home.packages = [
    (pkgs.writeShellScriptBin "dms-sync" ''
      src="${dmsConfigDest}"
      dest="${flakeDmsPath}"

      if [ ! -d "$src" ]; then
        echo "Diretório DMS não encontrado: $src"
        exit 1
      fi

      # Mostra diff antes de copiar
      changed=false
      for f in "$src"/*.kdl; do
        name="$(basename "$f")"
        if [ ! -f "$dest/$name" ]; then
          echo "NOVO: $name"
          changed=true
        elif ! cmp -s "$f" "$dest/$name"; then
          echo "MODIFICADO: $name"
          ${pkgs.diffutils}/bin/diff --color -u "$dest/$name" "$f" || true
          echo ""
          changed=true
        fi
      done

      if [ "$changed" = false ]; then
        echo "Nenhuma mudança detectada."
        exit 0
      fi

      printf "\nAplicar mudanças pro flake? [s/N] "
      read -r resp
      if [ "$resp" = "s" ] || [ "$resp" = "S" ]; then
        cp -v "$src"/*.kdl "$dest"/
        echo "Pronto! Lembre de commitar as mudanças no flake."
      else
        echo "Cancelado."
      fi
    '')
  ];

  # Activation script: copia os arquivos do flake pro destino (mutável, não symlink)
  home.activation.dmsConfig = config.lib.dag.entryAfter [ "writeBoundary" ] ''
    mkdir -p "${dmsConfigDest}"
    for f in ${dmsConfigSrc}/*.kdl; do
      dest="${dmsConfigDest}/$(basename "$f")"
      # Só copia se o arquivo do flake for diferente do atual
      if [ ! -f "$dest" ] || ! cmp -s "$f" "$dest"; then
        cp "$f" "$dest"
        chmod 644 "$dest"
      fi
    done
  '';
}
