# Segredos (agenix)

Segredos cifrados com [agenix](https://github.com/ryantm/agenix). Os arquivos
`.age` podem ir pro GitHub **público** — só quem tem uma chave privada listada em
`secrets.nix` consegue abrir.

## Chaves

- **Admin (pessoal):** `~/.config/receita-de-bolo.md` na máquina do Lucas
  (override com `$AGE_KEY`). Nome propositalmente discreto, mas é só cosmético —
  o real é cifrar o disco. ⚠️ Faça backup — sem ela não dá pra editar/re-cifrar.
  Pública: `age1fhrctt9...qanu`.
- **Hosts:** cada host descriptografa no boot com `/etc/ssh/ssh_host_ed25519_key`.
  A pública correspondente fica em `secrets.nix`.

## Editar um segredo existente

```bash
cd ~/RodoNixos
RULES=./secrets/secrets.nix \
  nix run github:ryantm/agenix -- -e secrets/aws-credentials.age \
  -i ~/.config/receita-de-bolo.md
```

(Os helpers `scripts/setup-cloud-secrets.sh` e `scripts/fix-cloud-secrets.sh`
também criam/recifram AWS e OCI sem editor.)

## Adicionar um novo host (ex: `rodomat`)

1. Suba o host (precisa ter `/etc/ssh/ssh_host_ed25519_key.pub` gerada).
2. Pegue a pública: `cat /etc/ssh/ssh_host_ed25519_key.pub`.
3. Em `secrets.nix`: descomente `rodomat`, cole a pública, e adicione-o aos
   `publicKeys` dos segredos que ele deve abrir.
4. Re-cifre pra incluir a nova chave:
   ```bash
   cd ~/RodoNixos
   RULES=./secrets/secrets.nix \
     nix run github:ryantm/agenix -- --rekey -i ~/.config/receita-de-bolo.md
   ```
5. No `default.nix` do host, declare os `age.secrets.*` (veja
   `hosts/rodolucas/default.nix` como exemplo).
6. `git add secrets/ && nixos-rebuild switch --flake .#rodomat`.

## Onde cada segredo é entregue (rodolucas)

| Segredo                | Caminho no boot              | Para        |
|------------------------|------------------------------|-------------|
| `aws-credentials.age`  | `~/.aws/credentials`         | `aws`       |
| `oci-config.age`       | `~/.oci/config`              | `oci`       |
| `oci-api-key.age`      | `~/.oci/oci_api_key.pem`     | `oci`       |
| `nas-smb-creds.age`    | `/run/agenix/nas-smb-creds`  | mount CIFS do NAS |

Região AWS e supressão de warning da OCI ficam em `users/lucasp.nix`
(`home.sessionVariables`), pois não são segredos.

(Backup do perfil do Zen: `zen-backup`/`zen-restore` — cifra `~/.zen` num bucket
OCI. Ver `users/programs/zen.nix`.)
