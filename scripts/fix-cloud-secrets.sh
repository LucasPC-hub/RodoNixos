#!/usr/bin/env bash
# Conserta os segredos de nuvem:
#   - AWS: re-cifra a secret key (validando 40 chars)
#   - OCI: remove a passphrase da private key e re-cifra
# RODE NO SEU TERMINAL:  bash ~/RodoNixos/scripts/fix-cloud-secrets.sh
set -euo pipefail

REPO="$HOME/RodoNixos"
cd "$REPO"

RECIPIENTS="$(mktemp)"
trap 'rm -f "$RECIPIENTS" ${TMP_KEY:-}' EXIT
cat > "$RECIPIENTS" <<'EOF'
age1fhrctt9huhe2yr9m9qv77vjvlf6ucl0aafn2x766vg9p4sj7jfjsw5qanu
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEk2OrBwxZjSL+u3CG/mOyDOzSoO/xyEMgv+22AvPe08
EOF
encrypt() { nix run nixpkgs#age -- -R "$RECIPIENTS" -o "$1"; }
trim() { printf '%s' "$1" | tr -d '[:space:]'; }

echo "=================== AWS ==================="
read -rp "AWS Access Key ID (AKIA...): " AWS_ID
AWS_ID="$(trim "$AWS_ID")"
while :; do
  read -rsp "AWS Secret Access Key (40 chars): " AWS_SECRET; echo
  AWS_SECRET="$(trim "$AWS_SECRET")"
  if [ "${#AWS_SECRET}" -eq 40 ]; then break; fi
  echo "  ⚠️  Tem ${#AWS_SECRET} chars, o esperado é 40. Tenta de novo (copie só a chave, sem espaços)."
done
printf '[default]\naws_access_key_id = %s\naws_secret_access_key = %s\n' \
  "$AWS_ID" "$AWS_SECRET" | encrypt secrets/aws-credentials.age
echo "  -> secrets/aws-credentials.age recifrado (secret com 40 chars ✔)"

echo "=================== OCI ==================="
echo "Removendo a passphrase da private key (digite a senha ATUAL da key uma vez)."
TMP_KEY="$(mktemp)"
# A key descriptografada (mas com passphrase) está em /run/agenix/oci-api-key
nix run nixpkgs#openssl -- rsa -in /run/agenix/oci-api-key -out "$TMP_KEY"
encrypt secrets/oci-api-key.age < "$TMP_KEY"
echo "  -> secrets/oci-api-key.age recifrado (sem passphrase ✔)"

echo
echo "Pronto! Volte pro Claude pra dar git add + rebuild."
