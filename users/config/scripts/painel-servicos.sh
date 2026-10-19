# Widget da área de trabalho (DMS desktopCommand): serviços do systemd.
# Falhas primeiro (vermelho), depois os do usuário e os do sistema rodando.

nomes() {
  "$@" list-units --type=service --state="$estado" --no-legend --plain 2>/dev/null \
    | awk '{sub(/\.service$/, "", $1); print $1}'
}

estado=failed
mapfile -t falhas_sis < <(nomes systemctl)
mapfile -t falhas_usr < <(nomes systemctl --user)
estado=running
mapfile -t sis < <(nomes systemctl)
mapfile -t usr < <(nomes systemctl --user)

nf=$(( ${#falhas_sis[@]} + ${#falhas_usr[@]} ))
printf '\033[1;35m⚙ Serviços\033[0m  \033[32m%s sistema · %s usuário\033[0m' "${#sis[@]}" "${#usr[@]}"
if [ "$nf" -gt 0 ]; then
  printf '  \033[1;31m%s com falha\033[0m\n' "$nf"
else
  printf '  \033[2m· nenhuma falha\033[0m\n'
fi

for s in "${falhas_sis[@]}" "${falhas_usr[@]}"; do
  printf '\033[31m✗ %s\033[0m\n' "$s"
done

colunas() { pr -2 -t -w 56 | sed 's/^/  /'; }

printf '\n\033[1;36mUsuário\033[0m\n'
printf '%s\n' "${usr[@]}" | cut -c1-25 | colunas
printf '\n\033[1;36mSistema\033[0m\n'
printf '%s\n' "${sis[@]}" | cut -c1-25 | colunas
