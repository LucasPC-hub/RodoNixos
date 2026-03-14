{ pkgs, lib, ... }:

{
  programs.zsh = {
    enable = true;
    autosuggestion = {
      enable = true;
      strategy = [ "history" "completion" ];
    };
    syntaxHighlighting.enable = true;
    enableCompletion = true;
    historySubstringSearch.enable = true;

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
    };

    plugins = [
      {
        name = "fzf-tab";
        src = pkgs.zsh-fzf-tab;
        file = "share/fzf-tab/fzf-tab.plugin.zsh";
      }
    ];

    initContent = lib.mkMerge [
      (lib.mkBefore ''
        # fzf-tab precisa carregar antes do compinit
        source ${pkgs.zsh-fzf-tab}/share/fzf-tab/fzf-tab.plugin.zsh
      '')
      ''
      # Opções do shell
      setopt AUTO_CD AUTO_PUSHD PUSHD_IGNORE_DUPS
      setopt CORRECT GLOB_DOTS EXTENDED_GLOB NO_BEEP
      setopt COMPLETE_IN_WORD INC_APPEND_HISTORY

      # Completion styles
      zstyle ':completion:*' menu select
      zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
      zstyle ':completion:*' list-colors "''${(s.:.)LS_COLORS}"
      zstyle ':completion:*' squeeze-slashes true
      zstyle ':completion:*' complete-options true
      zstyle ':completion:*' file-sort modification
      zstyle ':completion:*:descriptions' format '[%d]'
      zstyle ':completion:*:warnings' format 'Nada encontrado'

      # Cores
      export CLICOLOR=1
      export LS_COLORS='di=34:ln=35:so=32:pi=33:ex=31:bd=34;46:cd=34;43:su=30;41:sg=30;46:tw=30;42:ow=30;43'

      # FZF cores e preview
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

      # Key bindings
      bindkey -e
      bindkey '^[[1;5C' forward-word
      bindkey '^[[1;5D' backward-word
      bindkey '^[[3~' delete-char
      bindkey '^[[H' beginning-of-line
      bindkey '^[[F' end-of-line

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

      # Paths
      export PATH="$HOME/.local/bin:$PATH"

      # fzf-tab config
      zstyle ':completion:*:git-checkout:*' sort false
      zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -1 --color=always $realpath 2>/dev/null || ls -1 --color=always $realpath'
      zstyle ':fzf-tab:complete:z:*' fzf-preview 'eza -1 --color=always $realpath 2>/dev/null || ls -1 --color=always $realpath'
      zstyle ':fzf-tab:complete:*:*' fzf-preview 'bat --color=always --style=numbers --line-range=:500 $realpath 2>/dev/null || cat $realpath 2>/dev/null'
      zstyle ':fzf-tab:*' fzf-min-height 20
      zstyle ':fzf-tab:*' switch-group '<' '>'
      zstyle ':fzf-tab:*' fzf-flags --color=fg:1,fg+:2 --bind=tab:down,shift-tab:up

      # Carapace completions
      if command -v carapace &>/dev/null; then
        export CARAPACE_BRIDGES='zsh,fish,bash,inshellisense'
        source <(carapace _carapace)
      fi
    ''
    ];
  };

  # Programas que o zsh usa
  programs.starship.enable = true;
  programs.zoxide.enable = true;
  programs.atuin = {
    enable = true;
    enableZshIntegration = true;
  };
  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
  };
  programs.bat.enable = true;
  programs.eza.enable = true;

  home.packages = with pkgs; [
    carapace
  ];
}
