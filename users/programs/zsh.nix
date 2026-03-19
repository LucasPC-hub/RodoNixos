{ pkgs, lib, ... }:

{
  programs.zsh = {
    enable = true;
    # Desabilitados aqui — carregados via zsh-defer no initContent
    autosuggestion.enable = false;
    syntaxHighlighting.enable = false;
    enableCompletion = false;
    historySubstringSearch.enable = false;

    history = {
      size = 10000;
      save = 20000;
      ignoreDups = true;
      ignoreAllDups = true;
      ignoreSpace = true;
      share = true;
      append = true;
    };

    shellAliases = {
      ls = "eza --icons";
      ll = "eza -la --icons";
      lt = "eza --tree --level=2 --icons";
      cat = "bat";
      fkr = "cd ~/RodoNixos && niri-sync && sudo nixos-rebuild switch --flake '.#rodolucas'";
    };

    plugins = [ ];

    initContent = lib.mkMerge [
      (lib.mkBefore ''
        # zcompile cache — compila plugins pra binário .zwc
        _zsh_cache="$HOME/.cache/zsh/compiled"
        [[ -d "$_zsh_cache" ]] || mkdir -p "$_zsh_cache"

        # source compilado: copia do nix store, compila se necessário, e sourcea o .zwc
        _source_compiled() {
          local src="$1"
          local name="''${src:t}"
          local cached="$_zsh_cache/$name"
          if [[ ! -f "$cached.zwc" ]] || [[ "$src" -nt "$cached.zwc" ]]; then
            cp -f "$src" "$cached"
            zcompile "$cached"
          fi
          source "$cached"
        }

        # zsh-defer (precisa antes de tudo)
        _source_compiled ${pkgs.zsh-defer}/share/zsh-defer/zsh-defer.plugin.zsh
      '')
      ''
      # Opções do shell (leve, não precisa defer)
      setopt AUTO_CD AUTO_PUSHD PUSHD_IGNORE_DUPS
      setopt GLOB_DOTS EXTENDED_GLOB NO_BEEP
      setopt COMPLETE_IN_WORD INC_APPEND_HISTORY

      # Cores (leve, não precisa defer)
      export CLICOLOR=1
      export LS_COLORS='di=34:ln=35:so=32:pi=33:ex=31:bd=34;46:cd=34;43:su=30;41:sg=30;46:tw=30;42:ow=30;43'

      export FZF_DEFAULT_OPTS="
        --height 40%
        --layout=reverse
        --border
        --inline-info
        --color=fg:#c0caf5,bg:#1a1b26,hl:#7aa2f7
        --color=fg+:#c0caf5,bg+:#292e42,hl+:#7dcfff
        --color=info:#7aa2f7,prompt:#7dcfff,pointer:#7dcfff
        --color=marker:#9ece6a,spinner:#9ece6a,header:#9ece6a
      "
      export FZF_CTRL_T_OPTS="--preview 'bat --color=always --style=numbers --line-range=:500 {}' 2>/dev/null --preview-window right:50%:wrap"
      export FZF_ALT_C_OPTS="--preview 'eza --tree --level=2 --color=always {} 2>/dev/null' --preview-window right:50%"

      # Desabilita kitty keyboard protocol
      printf '\e[>4;0m'

      # Key bindings (leve)
      bindkey -e
      bindkey '^[[1;5C' forward-word
      bindkey '^[[1;5D' backward-word
      bindkey '^[[3~' delete-char
      bindkey '^[[H' beginning-of-line
      bindkey '^[[F' end-of-line

      # Paths
      export PATH="$HOME/.local/bin:$PATH"

      # === TUDO ABAIXO É DEFERIDO (carrega após o prompt) ===

      # fzf-tab + compinit (pesado)
      zsh-defer _source_compiled ${pkgs.zsh-fzf-tab}/share/fzf-tab/fzf-tab.plugin.zsh
      zsh-defer -c '
        autoload -Uz compinit
        if [[ -n ''${ZDOTDIR:-$HOME}/.zcompdump(#qN.mh+24) ]]; then
          compinit
        else
          compinit -C
        fi
      '

      # Completion styles (precisa rodar depois do compinit)
      zsh-defer -c '
        zstyle ":completion:*" menu select
        zstyle ":completion:*" matcher-list "m:{a-zA-Z}={A-Za-z}"
        zstyle ":completion:*" list-colors "''${(s.:.)LS_COLORS}"
        zstyle ":completion:*" squeeze-slashes true
        zstyle ":completion:*" complete-options true
        zstyle ":completion:*" file-sort modification
        zstyle ":completion:*:descriptions" format "[%d]"
        zstyle ":completion:*:warnings" format "Nada encontrado"
      '

      # fzf-tab config (depois do fzf-tab carregar)
      zsh-defer -c '
        zstyle ":completion:*:git-checkout:*" sort false
        zstyle ":fzf-tab:complete:cd:*" fzf-preview "eza -1 --color=always \$realpath 2>/dev/null || ls -1 --color=always \$realpath"
        zstyle ":fzf-tab:complete:z:*" fzf-preview "eza -1 --color=always \$realpath 2>/dev/null || ls -1 --color=always \$realpath"
        zstyle ":fzf-tab:complete:*:*" fzf-preview "bat --color=always --style=numbers --line-range=:500 \$realpath 2>/dev/null || cat \$realpath 2>/dev/null"
        zstyle ":fzf-tab:*" fzf-min-height 20
        zstyle ":fzf-tab:*" switch-group "<" ">"
        zstyle ":fzf-tab:*" fzf-flags --color=fg:1,fg+:2 --bind=tab:down,shift-tab:up
      '

      # Syntax highlighting (pesado)
      zsh-defer _source_compiled ${pkgs.zsh-syntax-highlighting}/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
      zsh-defer -c '
        ZSH_HIGHLIGHT_STYLES[dollar-double-quoted-argument]="fg=cyan"
        ZSH_HIGHLIGHT_STYLES[dollar-quoted-argument]="fg=cyan"
        ZSH_HIGHLIGHT_STYLES[assign]="fg=cyan"
      '

      # Autosuggestions
      zsh-defer _source_compiled ${pkgs.zsh-autosuggestions}/share/zsh-autosuggestions/zsh-autosuggestions.zsh
      zsh-defer -c 'ZSH_AUTOSUGGEST_STRATEGY=(history completion)'

      # History substring search
      zsh-defer _source_compiled ${pkgs.zsh-history-substring-search}/share/zsh-history-substring-search/zsh-history-substring-search.zsh

      # Integrações de programas (deferidas, exceto starship e direnv)
      zsh-defer -c 'eval "$(${pkgs.zoxide}/bin/zoxide init zsh)"'
      zsh-defer -c 'eval "$(${pkgs.fzf}/bin/fzf --zsh)"'
      zsh-defer -c 'eval "$(${pkgs.atuin}/bin/atuin init zsh)"'

      # Carapace completions (cacheado)
      export CARAPACE_BRIDGES='zsh,fish,bash,inshellisense'
      zsh-defer -c '
        local _carapace_cache="$HOME/.cache/carapace/init.zsh"
        if [[ ! -f "$_carapace_cache" ]] || [[ -n "$_carapace_cache"(#qN.mh+24) ]]; then
          mkdir -p "''${_carapace_cache:h}"
          carapace _carapace > "$_carapace_cache" 2>/dev/null
        fi
        [[ -f "$_carapace_cache" ]] && source "$_carapace_cache"
      '

      # Funções úteis
      mkcd() { mkdir -p "$1" && cd "$1" }

      extract() {
        if [ -f "$1" ]; then
          case "$1" in
            *.tar.bz2)   tar xjf "$1"     ;;
            *.tar.gz)    tar xzf "$1"     ;;
            *.bz2)       bunzip2 "$1"     ;;
            *.rar)       unrar x "$1"     ;;
            *.gz)        gunzip "$1"      ;;
            *.tar)       tar xf "$1"      ;;
            *.tbz2)      tar xjf "$1"     ;;
            *.tgz)       tar xzf "$1"     ;;
            *.zip)       unzip "$1"       ;;
            *.Z)         uncompress "$1"  ;;
            *.7z)        7z x "$1"        ;;
            *)           echo "'$1' não pode ser extraído" ;;
          esac
        else
          echo "'$1' não é um arquivo válido"
        fi
      }

      gc() {
        local file_status=$(git status --porcelain)
        git add .
        local commit_msg="''${1:-Auto-commit}"
        git commit -m "$commit_msg
      $file_status"
      }
    ''
    ];
  };

  # Programas que o zsh usa (integrações zsh desabilitadas — carregadas via zsh-defer)
  programs.zoxide = {
    enable = true;
    enableZshIntegration = false;
  };
  programs.atuin = {
    enable = true;
    enableZshIntegration = false;
  };
  programs.fzf = {
    enable = true;
    enableZshIntegration = false;
  };
  programs.direnv = {
    enableZshIntegration = true;
  };
  programs.starship = {
    enableZshIntegration = true;
  };
  programs.bat.enable = true;
  programs.eza.enable = true;

  home.packages = with pkgs; [
    carapace
    zsh-defer
  ];
}
