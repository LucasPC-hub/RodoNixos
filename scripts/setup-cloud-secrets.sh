#!/usr/bin/env bash
# Cifra as credenciais de nuvem (AWS + OCI) em secrets/*.age com `age`.
#
# RODE NO SEU TERMINAL (não pelo Claude) — os valores ficam só na sua máquina,
# nunca passam pelo chat. Ex:
#   bash ~/RodoNixos/scripts/setup-cloud-secrets.sh
set -euo pipefail

REPO="$HOME/RodoNixos"
cd "$REPO"
mkdir -p secrets

# Recipients = quem pode descriptografar. Chave admin (sua) + chave SSH do host.
# (idênticos ao secrets/secrets.nix — são chaves PÚBLICAS, ok versionar)
RECIPIENTS="$(mktemp)"
trap 'rm -f "$RECIPIENTS"' EXIT
cat > "$RECIPIENTS" <<'EOF'
age1fhrctt9huhe2yr9m9qv77vjvlf6ucl0aafn2x766vg9p4sj7jfjsw5qanu
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEk2OrBwxZjSL+u3CG/mOyDOzSoO/xyEMgv+22AvPe08
EOF

encrypt() { nix run nixpkgs#age -- -R "$RECIPIENTS" -o "$1"; }  # lê plaintext do stdin

echo "=================== AWS ==================="
read -rp "AWS Access Key ID (AKIA...): " AWS_ID
read -rsp "AWS Secret Access Key: " AWS_SECRET; echo
printf '[default]\naws_access_key_id = %s\naws_secret_access_key = %s\n' \
  "$AWS_ID" "$AWS_SECRET" | encrypt secrets/aws-credentials.age
echo "  -> secrets/aws-credentials.age criado"

echo "=================== OCI ==================="
if [ ! -f "$HOME/.oci/config" ]; then
  echo "Não achei ~/.oci/config — rodando o setup guiado da Oracle."
  echo "(Aceite os caminhos padrão. Ele gera a key e pede os OCIDs/região.)"
  nix run nixpkgs#oci-cli -- setup config
  echo
  echo ">>> IMPORTANTE: agora suba a PUBLIC key gerada (~/.oci/oci_api_key_public.pem)"
  echo ">>> no console da Oracle: Profile > User Settings > API Keys > Add API Key > Paste."
  read -rp "Pressione ENTER depois de subir a public key no console..." _
fi

KEYFILE="$(grep -E '^[[:space:]]*key_file' "$HOME/.oci/config" | head -1 | cut -d= -f2 | xargs)"
# Reescreve key_file pro caminho onde o agenix vai depositar a key no boot.
sed 's#^[[:space:]]*key_file[[:space:]]*=.*#key_file=/home/lucasp/.oci/oci_api_key.pem#' \
  "$HOME/.oci/config" | encrypt secrets/oci-config.age
encrypt secrets/oci-api-key.age < "$KEYFILE"
echo "  -> secrets/oci-config.age + secrets/oci-api-key.age criados"

echo
echo "Pronto! Segredos cifrados em secrets/. Volte pro Claude pra fazer o wire + rebuild."
