# Setup do host `rodomat`

Checklist pra subir o `rodomat` numa máquina **NixOS**. O `switch` **não** roda no
Arch — só na máquina NixOS de destino.

O que **já está declarativo** no repo (não precisa fazer à mão):
- Kernel **Zen** precompilado (`boot.kernelPackages = lib.mkForce pkgs.linuxPackages_zen`).
- Usuário `matt` (`/home/matt`, shell fish, grupos wheel/networkmanager/video/input/docker).
- Pacotes do Arch portados (`users/matt.nix` → `home.packages`).
- **Tailscale** habilitado (`services.tailscale.enable = true`).
- Chave **pública** do matt autorizada pra login (`authorizedKeys.keys`).
- **Aliases SSH** (`dokploy`, `ai`, `pve-cerebro`, `dues-remote`) via `programs.ssh.matchBlocks`.

O que é **manual** (segredo — não entra no repo): chaves SSH **privadas** e login do Tailscale.

---

## 1. Pegar o branch `matheus`

O branch vive no fork `matheuscararodojunior/RodoNixos` (sem acesso de escrita no upstream).

```bash
cd ~/RodoNixos
git remote add matheus-fork https://github.com/matheuscararodojunior/RodoNixos.git
git fetch matheus-fork
git checkout -b matheus matheus-fork/matheus
```

> Depois que abrir PR e o branch cair no upstream `LucasPC-hub/RodoNixos`, vira o simples:
> `git fetch && git checkout matheus`.

## 2. Build + switch

```bash
sudo nixos-rebuild switch --flake .#rodomat
```

Se quebrar em `termius` ou `vesktop` (apps com histórico de build instável), comenta a
linha em `users/matt.nix` e roda de novo.

## 3. Chaves SSH privadas (cópia à mão)

Rodar **do Arch** (`dias-rj`) depois que o `rodomat` estiver de pé e alcançável:

```bash
rsync -av \
  ~/.ssh/id_ed25519 ~/.ssh/ai_dokploy ~/.ssh/cerebro_pve ~/.ssh/dues_remote ~/.ssh/build-runner-key \
  matt@rodomat:~/.ssh/

ssh matt@rodomat 'chmod 700 ~/.ssh && chmod 600 ~/.ssh/{id_ed25519,ai_dokploy,cerebro_pve,dues_remote,build-runner-key}'
```

- **NÃO copiar `~/.ssh/config`** — o home-manager gera ele a partir dos `matchBlocks`. Copiar dá conflito.
- Opcional: `rsync -av ~/.ssh/*.pub ~/.ssh/known_hosts matt@rodomat:~/.ssh/`

## 4. Tailscale (login)

```bash
sudo tailscale up   # abre URL; logar como matheus.dias.dev@
```

(Pra preservar a identidade exata do nó, copiar `/var/lib/tailscale/tailscaled.state`
da máquina antiga com sudo — caso contrário entra como nó novo, que é o normal.)

---

## Pendências / notas

- **`ccstatusline`** não existe no nixpkgs (é npm). Se quiser, embrulhar com `bunx` igual o `omp` em `modules/programs/dev.nix`.
- **`tailscale`** ficou como serviço (daemon), não como pacote em `home.packages` — é o jeito certo.
- **IPs internos no repo**: os `matchBlocks` commitaram `192.168.2.x` / `100.89.12.37` / `user=root` no fork público. Não é credencial, mas expõe inventário. Se incomodar, mover os `hostname` pra fora do repo.
- **`programs.ssh`**: versões novas do home-manager podem emitir *warning* de deprecation (pedem `matchBlocks."*"`/`enableDefaultConfig`). É warning, não erro.
