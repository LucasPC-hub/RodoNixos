#!/usr/bin/env bash
# Alterna o "centralizar sempre" do DP-1 (Samsung Odyssey G9) entre always/never.
# Edita a linha marcada com `// dp1-center-toggle` no config ativo do niri;
# o niri recarrega o config sozinho ao detectar a mudança no arquivo.
set -euo pipefail

cfg="${HOME}/.config/niri/config.kdl"
marker="// dp1-center-toggle"

if grep -q "center-focused-column \"always\" ${marker}" "$cfg"; then
    sed -i "s|center-focused-column \"always\" ${marker}|center-focused-column \"never\" ${marker}|" "$cfg"
    state="OFF"
else
    sed -i "s|center-focused-column \"never\" ${marker}|center-focused-column \"always\" ${marker}|" "$cfg"
    state="ON"
fi

notify-send -t 1500 "Niri DP-1" "Centralizar automático: ${state}" 2>/dev/null || true
