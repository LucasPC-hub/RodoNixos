# Contexto global da laal

Lido por todas as ferramentas de IA do PC. Claude Code e Codex leem este arquivo
direto: `~/.claude/CLAUDE.md` e `~/.codex/AGENTS.md` são links para ele. Outras
ferramentas acham o caminho na variável `$AI_CONTEXTO`.

O arquivo de verdade fica em `~/RodoNixos/users/config/ai/CONTEXTO.md`. Pode
editar direto, sem rodar `fkr`.

## Máquina

- NixOS com flake em `~/RodoNixos` (host `laal`, branch `rodolaal`).
- Aplicar a config: `fkr`. Nunca instalar pacote com `nix-env` ou `nix profile`;
  pacotes vão em `users/perfil-laal.nix` (apps, também valem pro lucasbit),
  `users/laal.nix` (só da laal) ou `hosts/laal/` (sistema: `comum.nix` vale pro
  lucasbit, `default.nix` só pro PC da laal).
- Desktop: niri + DankMaterialShell (DMS), rodando como serviço `dms` do systemd
  do usuário.
- Shell: fish. Terminal: kitty. Navegador: Zen.

## Preferências

- Responder em português.

## Bancos da Rodojunior

- Credenciais locais em `~/.config/rodojunior/bancos.env` (fora de repo, permissão
  600). Carregar com `set -a; source ~/.config/rodojunior/bancos.env; set +a` no
  bash. Nunca copiar a senha para repo, log ou resposta.
- **SAT/Emisul de produção**: variáveis `SAT_PROD_*`. Também configurado como
  serviço `sat-prod` em `~/.pg_service.conf` + `~/.pgpass` (`psql service=sat-prod`,
  sessão já em modo só leitura). Usar só para leitura.
- O Infisical do `.env` do vitrum só enxerga `dev`; não usar ele para prod.

## Revisões de código

Quando eu pedir revisão ("as revisões", "as 3 revisões", "revisão de segurança",
"revisão de PR" etc.), seguir `~/RodoNixos/users/config/ai/REVISOES.md`. Revisão
só analisa e registra, nunca corrige.
