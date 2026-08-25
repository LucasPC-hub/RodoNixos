{ config, pkgs, ... }:

let
  homeDir = config.home.homeDirectory;
  niriDir = "${homeDir}/.config/niri";

  dmsConfigSrc = ../config/dms;
  niriConfigSrc = ../config/niri-config.kdl;
in
{
  home.activation.niriConfig = config.lib.dag.entryAfter [ "writeBoundary" ] ''
    # Sync config.kdl
    dest="${niriDir}/config.kdl"
    if [ ! -f "$dest" ] || ! cmp -s "${niriConfigSrc}" "$dest"; then
      cp "${niriConfigSrc}" "$dest"
      chmod 644 "$dest"
    fi

    # Sync dms/*.kdl (outputs.kdl is managed by DMS, never overwrite)
    mkdir -p "${niriDir}/dms"
    for f in ${dmsConfigSrc}/*.kdl; do
      name="$(basename "$f")"
      if [ "$name" = "outputs.kdl" ]; then continue; fi
      dest="${niriDir}/dms/$name"
      if [ ! -f "$dest" ] || ! cmp -s "$f" "$dest"; then
        cp "$f" "$dest"
        chmod 644 "$dest"
      fi
    done
  '';
}
