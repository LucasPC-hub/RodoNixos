# Mapa de segredos do agenix.
#
# Este arquivo NÃO é importado pelo NixOS — ele só é lido pela CLI `agenix`
# pra saber, ao cifrar cada `.age`, QUAIS chaves públicas podem descriptografar.
#
# Regra geral de cada segredo:
#   - `admin`  : sua chave age pessoal (~/.config/sops/age/keys.txt) — pra você
#                sempre conseguir editar/re-cifrar do seu PC.
#   - host key : a chave SSH pública do host que precisa abrir o segredo no boot.
#
# Pra editar um segredo:
#   cd ~/RodoNixos && RULES=./secrets/secrets.nix \
#     agenix -e secrets/aws-credentials.age -i ~/.config/sops/age/keys.txt
#
# Pra re-cifrar todos depois de mudar esta lista (ex: novo host):
#   cd ~/RodoNixos && RULES=./secrets/secrets.nix \
#     agenix --rekey -i ~/.config/sops/age/keys.txt
let
  # ── Chaves admin (pessoais) ────────────────────────────────────────────────
  admin = "age1fhrctt9huhe2yr9m9qv77vjvlf6ucl0aafn2x766vg9p4sj7jfjsw5qanu";

  # ── Chaves de host (SSH ed25519 de /etc/ssh/ssh_host_ed25519_key.pub) ──────
  rodolucas = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEk2OrBwxZjSL+u3CG/mOyDOzSoO/xyEMgv+22AvPe08 root@nixos";
  # rodomat = "ssh-ed25519 ...";  # preencher quando o host subir; depois rodar --rekey
in
{
  # Credenciais de nuvem — por enquanto só rodolucas (+ rodomat quando subir).
  "aws-credentials.age".publicKeys = [ admin rodolucas /* rodomat */ ];
  "oci-config.age".publicKeys = [ admin rodolucas /* rodomat */ ];
  "oci-api-key.age".publicKeys = [ admin rodolucas /* rodomat */ ];

  # .env de projetos de dev. Não são entregues pelo módulo NixOS; o comando
  # `rodoenv <projeto>` decifra com a chave age do usuário pra ./.env (qualquer
  # worktree/máquina). Por isso o recipient principal é a chave admin.
  "vitrum-env.age".publicKeys = [ admin rodolucas ];

  # Credenciais SMB do NAS (formato credentials= do mount.cifs). Lido pelo
  # root no boot pra montar o //10.1.1.251/Volume_1 — precisa da chave do host.
  "nas-smb-creds.age".publicKeys = [ admin rodolucas ];
}
