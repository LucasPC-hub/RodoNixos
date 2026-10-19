# Widget da área de trabalho (DMS desktopCommand): containers rodando.
# Saída com cores ANSI; o plugin converte para HTML.

if ! docker info >/dev/null 2>&1; then
  printf '\033[1;31m🐳 Docker parado\033[0m\n'
  exit 0
fi

mapfile -t linhas < <(docker ps --format '{{.Names}}\t{{.Status}}\t{{.Image}}')
total_parados=$(docker ps -aq --filter status=exited | wc -l)

printf '\033[1;36m🐳 Containers\033[0m  \033[32m%s rodando\033[0m  \033[2m· %s parados\033[0m\n\n' \
  "${#linhas[@]}" "$total_parados"

if [ "${#linhas[@]}" -eq 0 ]; then
  printf '\033[2mnenhum container rodando\033[0m\n'
  exit 0
fi

for l in "${linhas[@]}"; do
  IFS=$'\t' read -r nome status imagem <<<"$l"
  case "$status" in
    *unhealthy*) cor=31 ;;
    *healthy*)   cor=32 ;;
    *)           cor=33 ;;
  esac
  printf '\033[%sm●\033[0m \033[1m%-26.26s\033[0m \033[2m%s\033[0m\n' "$cor" "$nome" "$status"
  printf '   \033[2m%s\033[0m\n' "${imagem:0:40}"
done
