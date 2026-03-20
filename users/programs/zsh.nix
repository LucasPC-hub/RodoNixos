{ pkgs, lib, ... }:

{
  programs.zsh = {
    enable = true;
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
        #============================================
        # FZF-TAB (carrega antes do compinit!)
        #============================================
        source ${pkgs.zsh-fzf-tab}/share/fzf-tab/fzf-tab.plugin.zsh
      '')
      ''
      #============================================
      # Histórico
      #============================================
      setopt HIST_IGNORE_ALL_DUPS HIST_FIND_NO_DUPS HIST_SAVE_NO_DUPS
      setopt HIST_IGNORE_SPACE SHARE_HISTORY APPEND_HISTORY INC_APPEND_HISTORY

      #============================================
      # Opções do Shell
      #============================================
      setopt AUTO_CD AUTO_PUSHD PUSHD_IGNORE_DUPS
      setopt CORRECT GLOB_DOTS EXTENDED_GLOB NO_BEEP
      setopt COMPLETE_IN_WORD

      #============================================
      # Completion System
      #============================================
      autoload -Uz compinit
      if [[ -n ~/.zcompdump(#qN.mh+24) ]]; then
        compinit
      else
        compinit -C
      fi

      zstyle ':completion:*' menu select
      zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
      zstyle ':completion:*' list-colors "''${(s.:.)LS_COLORS}"
      zstyle ':completion:*' squeeze-slashes true
      zstyle ':completion:*' complete-options true
      zstyle ':completion:*' file-sort modification
      zstyle ':completion:*:descriptions' format '[%d]'
      zstyle ':completion:*:warnings' format 'Nada encontrado'

      #============================================
      # CARAPACE - Completions inteligentes
      #============================================
      export CARAPACE_BRIDGES='zsh,fish,bash,inshellisense'
      zstyle ':completion:*' format $'\e[2;37mCompleting %d\e[m'
      _carapace_cache="$HOME/.cache/carapace_init.zsh"
      if [[ ! -f "$_carapace_cache" || "$commands[carapace]" -nt "$_carapace_cache" ]]; then
        mkdir -p "$HOME/.cache"
        carapace _carapace > "$_carapace_cache"
      fi
      source "$_carapace_cache"

      #============================================
      # Cores
      #============================================
      autoload -U colors && colors
      export CLICOLOR=1
      export LS_COLORS='di=34:ln=35:so=32:pi=33:ex=31:bd=34;46:cd=34;43:su=30;41:sg=30;46:tw=30;42:ow=30;43'

      #============================================
      # Funções úteis
      #============================================
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

      #============================================
      # FZF
      #============================================
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

      #============================================
      # Syntax Highlighting
      #============================================
      source ${pkgs.zsh-syntax-highlighting}/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
      typeset -A ZSH_HIGHLIGHT_STYLES
      ZSH_HIGHLIGHT_STYLES[default]='none'
      ZSH_HIGHLIGHT_STYLES[unknown-token]='fg=red,bold'
      ZSH_HIGHLIGHT_STYLES[reserved-word]='fg=yellow'
      ZSH_HIGHLIGHT_STYLES[alias]='fg=green'
      ZSH_HIGHLIGHT_STYLES[builtin]='fg=green'
      ZSH_HIGHLIGHT_STYLES[function]='fg=green'
      ZSH_HIGHLIGHT_STYLES[command]='fg=green'
      ZSH_HIGHLIGHT_STYLES[precommand]='fg=green,underline'
      ZSH_HIGHLIGHT_STYLES[commandseparator]='none'
      ZSH_HIGHLIGHT_STYLES[hashed-command]='fg=green'
      ZSH_HIGHLIGHT_STYLES[path]='underline'
      ZSH_HIGHLIGHT_STYLES[globbing]='fg=blue'
      ZSH_HIGHLIGHT_STYLES[history-expansion]='fg=blue'
      ZSH_HIGHLIGHT_STYLES[single-hyphen-option]='fg=magenta'
      ZSH_HIGHLIGHT_STYLES[double-hyphen-option]='fg=magenta'
      ZSH_HIGHLIGHT_STYLES[back-quoted-argument]='none'
      ZSH_HIGHLIGHT_STYLES[single-quoted-argument]='fg=yellow'
      ZSH_HIGHLIGHT_STYLES[double-quoted-argument]='fg=yellow'
      ZSH_HIGHLIGHT_STYLES[dollar-double-quoted-argument]='fg=cyan'
      ZSH_HIGHLIGHT_STYLES[back-double-quoted-argument]='fg=cyan'
      ZSH_HIGHLIGHT_STYLES[assign]='none'

      #============================================
      # Autosuggestions
      #============================================
      source ${pkgs.zsh-autosuggestions}/share/zsh-autosuggestions/zsh-autosuggestions.zsh
      ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=240'
      ZSH_AUTOSUGGEST_STRATEGY=(history completion)
      ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=20

      #============================================
      # Key Bindings
      #============================================
      bindkey -e
      bindkey '^[[1;5C' forward-word
      bindkey '^[[1;5D' backward-word
      bindkey '^[[3~' delete-char
      bindkey '^[[H' beginning-of-line
      bindkey '^[[F' end-of-line

      # Desabilita kitty keyboard protocol
      printf '\e[>4;0m'

      #============================================
      # _cache_eval - cacheia output de comandos init
      #============================================
      _cache_eval() {
        local cache="$HOME/.cache/zsh_''${1}.zsh"
        if [[ ! -f "$cache" ]]; then
          mkdir -p "$HOME/.cache"
          "$@" > "$cache"
        fi
        source "$cache"
      }

      #============================================
      # Starship Prompt
      #============================================
      _cache_eval starship init zsh

      #============================================
      # Zoxide
      #============================================
      _cache_eval zoxide init zsh

      #============================================
      # Atuin
      #============================================
      eval "$(atuin init zsh)"
      export ATUIN_NOBIND="true"
      bindkey '^r' _atuin_search_widget
      bindkey '^[[A' _atuin_search_widget
      bindkey '^[OA' _atuin_search_widget

      #============================================
      # FZF-TAB Config
      #============================================
      zstyle ':completion:*:git-checkout:*' sort false
      zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -1 --color=always $realpath 2>/dev/null || ls -1 --color=always $realpath'
      zstyle ':fzf-tab:complete:z:*' fzf-preview 'eza -1 --color=always $realpath 2>/dev/null || ls -1 --color=always $realpath'
      zstyle ':fzf-tab:complete:*:*' fzf-preview 'bat --color=always --style=numbers --line-range=:500 $realpath 2>/dev/null || cat $realpath 2>/dev/null'
      zstyle ':fzf-tab:*' fzf-min-height 20
      zstyle ':fzf-tab:*' switch-group '<' '>'
      zstyle ':fzf-tab:*' fzf-flags --color=fg:1,fg+:2 --bind=tab:down,shift-tab:up

      #============================================
      # Paths
      #============================================
      export PATH="$HOME/.local/bin:$PATH"
      setopt interactivecomments
    ''
    ];
  };

  # Programas (integrações zsh desabilitadas — gerenciadas manualmente acima)
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
    enableZshIntegration = false;
  };
  programs.starship = {
    enableZshIntegration = false;
  };
  programs.bat.enable = true;
  programs.eza.enable = true;

  home.packages = with pkgs; [
    carapace
  ];
}
