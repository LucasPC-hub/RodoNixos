{ config, ... }:

let
  # Contexto global das IAs. Link "fora do store" para o arquivo do repo: dá
  # pra editar direto (inclusive pelas próprias IAs) sem rodar fkr.
  aiContexto = "${config.home.homeDirectory}/RodoNixos/users/config/ai/CONTEXTO.md";
in
{
  # Apps, Dolphin e ajustes do desktop vêm do perfil (compartilhado com o lucasbit).
  imports = [
    ./perfil-laal.nix
  ];

  home.username = "laal";
  home.homeDirectory = "/home/laal";
  home.stateVersion = "25.05";

  home.file.".claude/CLAUDE.md".source = config.lib.file.mkOutOfStoreSymlink aiContexto;
  home.file.".codex/AGENTS.md".source = config.lib.file.mkOutOfStoreSymlink aiContexto;

  # Variáveis de todo o PC: valem no terminal e nos apps gráficos (depois de
  # sair e entrar na sessão). Qualquer ferramenta lê com $AI_CONTEXTO.
  home.sessionVariables.AI_CONTEXTO = aiContexto;

  # Identidade git — aqui e não em users/shared.nix, senão todo mundo
  # commitaria com a conta da laal.
  programs.git.settings.user = {
    name = "laralimamota";
    email = "llmotadev@gmail.com";
  };

  # Aliases só da laal (somam com os compartilhados em users/programs/fish.nix)
  programs.fish.shellAliases = {
    sotao = "cd ${config.home.homeDirectory}/develop/laal/sotao-cerebral";
  };
}
