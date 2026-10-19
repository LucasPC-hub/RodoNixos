# Mudanças no Nix da laal

Lista do que eu quero mudar no meu NixOS. Vou acrescentando pedidos novos no
fim, e a IA marca o que já foi feito e onde ficou.

Depois de qualquer mudança nos arquivos `.nix`: rodar `fkr` para aplicar.
Variáveis de ambiente novas só aparecem nos apps gráficos depois de sair e
entrar de novo na sessão.

## Pedidos

| # | Pedido | Status | Onde ficou |
|---|--------|--------|------------|
| 1 | Gerenciador de tarefas parecido com o do Windows | feito | `mission-center` em `users/laal.nix` |
| 2 | Entender variáveis de ambiente e aliases no Nix | feito | seção [Como funciona](#como-funciona) abaixo |
| 3 | Variáveis acessíveis em todo o PC, com um contexto que as IAs consultam | feito | `AI_CONTEXTO` em `users/laal.nix`, arquivo em `users/config/ai/CONTEXTO.md` |
| 4 | Comando `ajuda`: cola bonita e categorizada de aliases, SSH, NixOS, DMS e Linux | feito | `users/config/fish/ajuda.fish` |
| 5 | RAM consumida por loop de erro do DMS depois da suspensão | feito | `systemd.user.services.dms` em `hosts/laal/default.nix` |
| 6 | Comando `pids`: todos os processos rodando, com descrição | feito | `users/config/scripts/pids.sh` |
| 7 | (consequência) Build quebrado pelo `flake.lock` novo: plugin `obs-composite-blur` não compilava | resolvido no 8 | OBS desinstalado |
| 8 | Desinstalar DataGrip duplicado, Thunar, Nautilus, Firefox Dev, htop, Insomnia, Meld, VS Code, OBS, Discord | feito | `dev.nix`, `modules/programs/shared.nix`, `users/shared.nix`, `users/laal.nix`; `Super+E` agora abre o yazi no kitty; seletor de arquivos ("Salvar como") usa o diálogo GTK |
| 9 | Desinstalar tudo do LibreOffice | feito | `users/laal.nix` (com os dicionários hunspell), `users/jaisla.nix` |
| 10 | Dolphin como explorador de arquivos, com plugins | feito | pacotes `kdePackages.*` e `menus/applications.menu` em `users/laal.nix`; `Super+E` em `users/config/dms/binds.kdl`; pastas abrem no Dolphin (`~/.config/mimeapps.list`) |
| 11 | Mais extras no Dolphin: admin, pastas remotas, uso de disco, busca, Okular, Gwenview, ações no botão direito, visual Breeze | feito | `users/laal.nix` (pacotes, `QT_STYLE_OVERRIDE`, serviço `baloo-file`, `kio/servicemenus`); `kio-admin`/`kio-fuse` em `hosts/laal/default.nix` |
| 12 | Tirar o yazi (dava erro no `theme.toml`) | feito | `programs.yazi.enable = mkForce false` em `users/laal.nix`; continua em `users/shared.nix` para os outros usuários |
| 13 | Instalar OnlyOffice, com melhorias | feito | `onlyoffice` em `users/laal.nix`, com fontes da Microsoft (corefonts, vista-fonts) montadas em `/usr/share/fonts` do sandbox dele |
| 14 | DMS estilo liquid glass, widgets na área de trabalho e plugins novos na barra | feito | blur dos widgets em `users/config/niri-config.kdl` (`layer-rule`); dependências dos plugins e scripts `painel-docker`/`painel-servicos` em `users/laal.nix`; Qt5Compat do DMS em `hosts/laal/default.nix`; o resto é configuração do próprio DMS (`~/.config/DankMaterialShell`, backup em `backup-2026-10-15-11-49/`) |
| 15 | Barra igual à do Matheus, cores dinâmicas neutras, Inter, cantos 12, atalhos novos, Dolphin de vidro e com menos zoom | feito | barra/tema na config do DMS (backup em `~/.config/DankMaterialShell/backup-*`); atalhos em `users/config/dms/binds.kdl`; Dolphin: wrapper `QT_SCALE_FACTOR=1.15` em `users/laal.nix` e regra `opacity`/blur em `users/config/niri-config.kdl` |
| 16 | Ícones próprios pro Dolphin e o ZapZap | feito | PNGs em `users/config/icons/`, `.desktop` com `Icon=` trocado em `users/laal.nix` |
| 17 | Trazer do repo do Matheus: widgets da área de trabalho, widgets novos de barra + NordHub, ChatGPT, Bitwarden, limpeza de cache, `ajuda`, Dolphin (Darkly, miniaturas, caminho no título), fontes, atalhos; ícones Kora | feito | plugins em `hosts/laal/dms-plugins/` e `hosts/laal/dms-extras.nix` (com ChatGPT, helpers do Bitwarden e `nix-command-catalog`); limpeza em `hosts/laal/manutencao.nix`; `ajuda`/`comandos` em `users/config/fish/`; Dolphin, Kora e fontes em `users/laal.nix`; atalhos em `users/config/dms/binds.kdl`; posições/barra na config do DMS |
| 18 | Setinha "Ícones ocultos" com todas as ferramentas do NordHub ativas, mais os apps em segundo plano | feito | catálogo único em `hosts/laal/dms-plugins/NordHub/Ferramentas.js` (usado pelo NordHub e pela `BandejaOculta`); Kaomoji em `hosts/laal/dms-extras.nix`; hosts desligados dos widgets na Main Bar (config do DMS, carregam sob demanda) |
| 19 | Espelho deixava a câmera ligada depois de fechar | feito | `hosts/laal/patches/hand-mirror-camera.patch`, aplicado no `handMirror` em `hosts/laal/dms-extras.nix` (a cópia da loja em `~/.config/DankMaterialShell/plugins` foi removida) |

### Novos pedidos

- (escreva aqui)

## Como funciona

### Onde cada coisa é configurada

| O quê | Arquivo | Vale para |
|---|---|---|
| Apps, Dolphin, scripts e ajustes do desktop | `users/perfil-laal.nix` | laal e lucasbit |
| Git, contexto das IAs e aliases só meus | `users/laal.nix` | só a laal |
| Aliases e funções do fish de todo mundo | `users/programs/fish.nix` | todos os usuários do repo |
| Sistema comum ao meu ambiente (DMS, plugins, Dolphin, fontes, energia) | `hosts/laal/comum.nix`, `hosts/laal/dms-extras.nix` | PCs `laal` e `rodolucasbit` |
| Sistema só do meu PC (nvidia, tela 165 Hz, tailscale, DLNA) | `hosts/laal/default.nix` | o PC `laal` |
| Notebook do lucasbit (Aspire 5, Intel) | `hosts/rodolucasbit/`, `users/lucasbit.nix` | o PC `rodolucasbit` |
| Módulos compartilhados entre PCs | `modules/...` | todo host que importa o módulo |

O repo é compartilhado com outras pessoas (rodolucas, jaisla...). Mudança que é
só minha vai em `users/laal.nix` ou `hosts/laal/default.nix`; o que vai em
`users/perfil-laal.nix` ou `hosts/laal/comum.nix` chega também no lucasbit.

O lucasbit recebe a minha DankBar a partir de `users/config/dms-shell/` (uma
vez só, ver `users/programs/dankbar-laal.nix`) e os plugins da loja do DMS a
partir do `plugins.lock.json` de lá (`hosts/rodolucasbit/dms-loja.nix`).

### Aliases

Alias é um apelido para um comando. No fish eles ficam em
`programs.fish.shellAliases`:

```nix
programs.fish.shellAliases = {
  sotao = "cd ~/develop/laal/sotao-cerebral";
};
```

Quando o comando precisa de lógica (if, argumentos), vira função, em
`programs.fish.functions` (veja `fkr`, `nsh`, `mkcd` em
`users/programs/fish.nix`) ou num arquivo `.fish` próprio, como o
`ajuda.fish`.

Para ver todos: `ajuda aliases`. Para saber de onde vem um comando:
`type <nome>`.

### Variáveis de ambiente

Variável de ambiente é um par `NOME=valor` que todo programa recebe ao abrir.
Ex: `EDITOR=vim` diz para qualquer programa qual editor abrir. Ler no terminal:
`echo $EDITOR`. Listar todas: `env`.

No Nix existem três lugares, do mais restrito para o mais amplo:

| Opção | Arquivo | Alcance |
|---|---|---|
| `set -gx NOME valor` dentro de `programs.fish.interactiveShellInit` | `users/programs/fish.nix` | só terminais fish |
| `home.sessionVariables` | `users/laal.nix` | **tudo da minha sessão**: terminal, apps gráficos, serviços do usuário (dms) |
| `environment.sessionVariables` | `hosts/laal/default.nix` | todos os usuários do PC, inclusive root |

Para "acessível por todo o PC" use `home.sessionVariables`. Conferido: as que
já estão lá (`EDITOR`, `BROWSER`...) aparecem até no processo do DMS.

```nix
home.sessionVariables = {
  MINHA_VARIAVEL = "valor";
};
```

Não coloque senhas ou tokens aqui: tudo que está no Nix vai parar no
`/nix/store`, que qualquer usuário do PC consegue ler. Segredos vão em
`secrets/` (agenix).

### Contexto global das IAs

- O texto fica em `users/config/ai/CONTEXTO.md`.
- `~/.claude/CLAUDE.md` (Claude Code) e `~/.codex/AGENTS.md` (Codex) são links
  para ele, então essas duas ferramentas leem automaticamente.
- Qualquer outra ferramenta acha o arquivo pela variável `$AI_CONTEXTO`.
- É um link para o arquivo do repo (não uma cópia no store): dá para editar
  direto, sem `fkr`. Não esqueça de commitar.

## Diagnóstico do loop do DMS (item 5)

Em 30/09/2026 às 15:14 o PC suspendeu e voltou às 16:04. Na volta, o
`quickshell` (a parte visual do DMS) escreveu `QSocketNotifier: Invalid socket
... disabling` sem parar: 2,5 milhões de linhas em ~35 minutos, até o PC ser
reiniciado. Logo antes aparece `pw_stream_connect failed "No such device"`.

Causa: bug conhecido do Quickshell com Qt 6.11. O backend de áudio PipeWire
do QtMultimedia (usado pelos sons do DMS) não se reconecta direito depois da
suspensão e fica num loop sobre um socket já fechado.

Correção em `hosts/laal/default.nix`:

- `QT_AUDIO_BACKEND=pulseaudio` no serviço `dms`: o Qt passa a usar o
  PulseAudio (que no NixOS é o `pipewire-pulse`), que não tem o bug. O som
  continua funcionando igual.
- `MemoryMax=2G`: se algum outro loop aparecer, o systemd mata o DMS ao passar
  de 2 GiB e ele volta sozinho em ~1 s. Normal dele: 0,5 a 0,8 GiB.

Para conferir se voltou a acontecer:
`journalctl --user -u dms -b | grep -c QSocketNotifier` (deve dar 0).
