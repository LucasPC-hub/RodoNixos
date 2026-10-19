#!/usr/bin/env bash
# pids: lista os processos rodando, com o app "dono" e o pacote de cada um.
#
#   pids            todos, ordenados por RAM
#   pids zapzap     só as linhas que contêm "zapzap" (sem diferenciar maiúsc.)
#   pids -c         ordena por CPU em vez de RAM
#
# Colunas:
#   APP     a quem o processo pertence: serviço do systemd (dms, pipewire...) ou
#           o app que abriu ele (ex: os QtWebEngineProcess do ZapZap mostram
#           "zapzap"). Vem do cgroup/unit do systemd.
#   PACOTE  pacote do Nix de onde vem o executável (ex: qtwebengine-6.11.2).
set -euo pipefail

sort_col=5 # RAM
if [[ ${1:-} == -c ]]; then sort_col=4; shift; fi
filter=${1:-}

# ps do procps: o builtin de alguns shells não conhece uunit/unit/exe.
# comm vai por último porque pode ter espaço ("Isolated Web Co").
ps -eo pid=,user=,pcpu=,rss=,uunit=,unit=,exe:4096=,comm= |
  awk -v filter="${filter,,}" -v self=$$ '
    # Nome legível: tira o "." e o "-wrapped" que os wrappers do Nix adicionam
    # (inclusive cortado, como em "zen-beta-wrapp").
    function clean(n) { sub(/^\./, "", n); sub(/-w(r(a(p(p(e(d)?)?)?)?)?)?$/, "", n); return n }
    {
      pid = $1; if (pid == self) next
      exe = $7; f = 8
      if ($8 == "(deleted)") f = 9
      comm = $f; for (i = f + 1; i <= NF; i++) comm = comm " " $i
      name = clean(comm)
      base = exe; sub(/.*\//, "", base); base = clean(base)
      # comm é cortado em 15 caracteres pelo kernel; usa o nome do executável
      # quando ele é a versão completa do mesmo nome.
      if (length(comm) == 15 && index(base, name) == 1) name = base
      user[pid] = $2; cpu[pid] = $3; rss[pid] = $4; nm[pid] = name
      unit[pid] = $5 != "-" ? $5 : $6
      # exe "-": thread do kernel (sem unit) ou processo de outro usuário,
      # cujo executável só aparece rodando com sudo.
      pkg = exe != "-" ? exe : unit[pid] == "-" ? "kernel" : "? (use sudo)"
      if (pkg ~ /^\/nix\/store\//) { sub(/^\/nix\/store\/[^-]*-/, "", pkg); sub(/\/.*/, "", pkg) }
      pk[pid] = pkg
      order[++n] = pid
    }
    END {
      for (k = 1; k <= n; k++) {
        pid = order[k]; u = unit[pid]
        if (u ~ /^run-p[0-9]+-/) {
          # scope genérico do launcher: run-p<PID-do-líder>-i<n>.scope.
          # Se o líder já morreu, usa o nome do próprio processo.
          leader = u; sub(/^run-p/, "", leader); sub(/-.*/, "", leader)
          app = (leader in nm) ? nm[leader] : nm[pid]
        } else if (u ~ /^app-/) {
          # app-niri-kitty-1234.scope, app-org.chromium.Chromium-26418.scope
          app = u; sub(/^app-/, "", app); sub(/@.*/, "", app); sub(/\.(scope|service)$/, "", app)
          sub(/-[0-9]+$/, "", app); sub(/.*-/, "", app); sub(/.*\./, "", app)
        } else if (u ~ /^docker-/) app = "docker:" substr(u, 8, 12)
        else if (u ~ /^session-[0-9]+\.scope$/) app = "login"
        else if (u == "init.scope") app = "systemd"
        else if (u == "-") app = "kernel"
        else { app = u; sub(/\.(scope|service|slice)$/, "", app); sub(/-[0-9]+(-[0-9]+)?$/, "", app) }
        line = pid "\t" user[pid] "\t" app "\t" cpu[pid] "\t" rss[pid] "\t" nm[pid] "\t" pk[pid]
        if (filter == "" || index(tolower(line), filter)) print line
      }
    }' |
  sort -t$'\t' -k"$sort_col,$sort_col" -rn |
  awk -F'\t' -v OFS='\t' '
    function human(kb) {
      return kb >= 1048576 ? sprintf("%.1fG", kb / 1048576) : kb >= 1024 ? sprintf("%dM", kb / 1024) : kb "K"
    }
    BEGIN { print "PID", "USUARIO", "APP", "CPU%", "RAM", "PROCESSO", "PACOTE" }
    { $5 = human($5); print }' |
  column -t -s$'\t'
