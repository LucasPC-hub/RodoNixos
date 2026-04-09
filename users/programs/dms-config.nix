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
