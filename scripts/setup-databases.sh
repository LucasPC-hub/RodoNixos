#!/usr/bin/env bash
# Cadastra conexões de banco num cofre cifrado (secrets/databases.age).
# Réplicas (hml/prod/dev com mesma senha): deixe o campo em branco pra repetir
# o valor anterior — assim você muda só nome e host.
#
# RODE NO SEU TERMINAL:  bash ~/RodoNixos/scripts/setup-databases.sh
set -euo pipefail
cd ~/RodoNixos

RECIPIENTS="$(mktemp)"; ENTRIES="$(mktemp)"
trap 'rm -f "$RECIPIENTS" "$ENTRIES"' EXIT
cat > "$RECIPIENTS" <<'EOF'
age1fhrctt9huhe2yr9m9qv77vjvlf6ucl0aafn2x766vg9p4sj7jfjsw5qanu
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEk2OrBwxZjSL+u3CG/mOyDOzSoO/xyEMgv+22AvPe08
EOF
JQ() { nix run nixpkgs#jq -- "$@"; }

# Se já existe um cofre, começa dele (pra não perder o que já tem).
key="$HOME/.config/sops/age/keys.txt"
if [ -f secrets/databases.age ]; then
  echo "Cofre existente encontrado — novos bancos serão ADICIONADOS a ele."
  nix run nixpkgs#age -- -d -i "$key" secrets/databases.age | JQ -c '.[]' > "$ENTRIES" 2>/dev/null || true
fi

def_type=postgresql; def_port=5432; def_db=""; def_user=""; def_pass=""
default_port() { case "$1" in postgresql) echo 5432;; mysql|mariadb) echo 3306;; sqlserver) echo 1433;; oracle) echo 1521;; *) echo "";; esac; }

echo "== Cadastro de bancos (deixe o NOME vazio pra terminar) =="
while :; do
  echo
  read -rp "Nome da conexão (ex: vitrum-prod) [vazio=fim]: " name
  [ -z "$name" ] && break
  read -rp "Tipo (postgresql/mysql/mariadb/sqlserver/oracle) [$def_type]: " type; type="${type:-$def_type}"
  dp="$(default_port "$type")"; [ -n "$def_port" ] && dp="$def_port"
  read -rp "Host: " host
  read -rp "Porta [$dp]: " port; port="${port:-$dp}"
  read -rp "Database [${def_db:-}]: " db; db="${db:-$def_db}"
  read -rp "Usuário [${def_user:-}]: " user; user="${user:-$def_user}"
  read -rsp "Senha [Enter = repetir a anterior]: " pass; echo
  [ -z "$pass" ] && pass="$def_pass"

  JQ -nc --arg name "$name" --arg type "$type" --arg host "$host" \
        --arg port "$port" --arg db "$db" --arg user "$user" --arg pass "$pass" \
        '{name:$name,type:$type,host:$host,port:($port|tonumber),db:$db,user:$user,password:$pass}' \
        >> "$ENTRIES"
  echo "  + $name ($type @ $host:$port)"
  def_type="$type"; def_port="$port"; def_db="$db"; def_user="$user"; def_pass="$pass"
done

n=$(wc -l < "$ENTRIES" | tr -d ' ')
[ "$n" -eq 0 ] && { echo "Nada cadastrado."; exit 0; }
JQ -s '.' "$ENTRIES" | nix run nixpkgs#age -- -R "$RECIPIENTS" -o secrets/databases.age
echo
echo "Pronto! $n conexões cifradas em secrets/databases.age"
echo "Depois do switch, gere o arquivo de import com:  db-export"
