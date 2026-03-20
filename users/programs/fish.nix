{ pkgs, lib, ... }:

{
  programs.fish = {
    enable = true;

    shellAliases = {
      ls = "eza --icons";
      ll = "eza -la --icons";
      lt = "eza --tree --level=2 --icons";
      cat = "bat";
      fkr = "cd ~/RodoNixos && niri-sync && sudo nixos-rebuild switch --flake '.#rodolucas'";
    };

    functions = {
      # Cria diretório e entra nele
      mkcd = "mkdir -p $argv[1] && cd $argv[1]";

      # Extrai qualquer arquivo compactado
      extract = ''
        if test -f $argv[1]
          switch $argv[1]
            case '*.tar.bz2'; tar xjf $argv[1]
            case '*.tar.gz';  tar xzf $argv[1]
            case '*.bz2';     bunzip2 $argv[1]
            case '*.rar';     unrar x $argv[1]
            case '*.gz';      gunzip $argv[1]
            case '*.tar';     tar xf $argv[1]
            case '*.tbz2';    tar xjf $argv[1]
            case '*.tgz';     tar xzf $argv[1]
            case '*.zip';     unzip $argv[1]
            case '*.Z';       uncompress $argv[1]
            case '*.7z';      7z x $argv[1]
            case '*';         echo "'$argv[1]' não pode ser extraído"
          end
        else
          echo "'$argv[1]' não é um arquivo válido"
        end
      '';

      # Git commit rápido
      gc = ''
        set file_status (git status --porcelain)
        git add .
        set commit_msg (if test (count $argv) -gt 0; echo $argv[1]; else; echo "Auto-commit"; end)
        git commit -m "$commit_msg
$file_status"
      '';
    };

    interactiveShellInit = ''
      #============================================
      # Opções do Shell
      #============================================
      set -g fish_greeting ""

      #============================================
      # Cores
      #============================================
      set -gx CLICOLOR 1
      set -gx LS_COLORS 'di=34:ln=35:so=32:pi=33:ex=31:bd=34;46:cd=34;43:su=30;41:sg=30;46:tw=30;42:ow=30;43'

      #============================================
      # FZF
      #============================================
      set -gx FZF_DEFAULT_OPTS "
        --height 40%
        --layout=reverse
        --border
        --inline-info
        --color=fg:#c0caf5,bg:#1a1b26,hl:#7aa2f7
        --color=fg+:#c0caf5,bg+:#292e42,hl+:#7dcfff
        --color=info:#7aa2f7,prompt:#7dcfff,pointer:#7dcfff
        --color=marker:#9ece6a,spinner:#9ece6a,header:#9ece6a
      "
      set -gx FZF_CTRL_T_OPTS "--preview 'bat --color=always --style=numbers --line-range=:500 {}' --preview-window right:50%:wrap"
      set -gx FZF_ALT_C_OPTS "--preview 'eza --tree --level=2 --color=always {} 2>/dev/null' --preview-window right:50%"

      #============================================
      # CARAPACE
      #============================================
      set -gx CARAPACE_BRIDGES 'zsh,fish,bash,inshellisense'
      carapace _carapace fish | source

      #============================================
      # Atuin
      #============================================
      set -gx ATUIN_NOBIND true
      atuin init fish | source
      bind \cr _atuin_search
      bind \e\[A _atuin_search
      bind \eOA _atuin_search

      #============================================
      # Desabilita kitty keyboard protocol
      #============================================
      printf '\e[>4;0m'

      #============================================
      # Paths
      #============================================
      fish_add_path -g $HOME/.local/bin
    '';
  };

  # Programas com integração fish
  programs.zoxide = {
    enable = true;
    enableFishIntegration = true;
  };
  programs.fzf = {
    enable = true;
    enableFishIntegration = true;
  };
  programs.starship = {
    enableFishIntegration = true;
  };
  programs.direnv = {
    enableZshIntegration = false;
    enableFishIntegration = true;
  };
  programs.atuin = {
    enable = true;
    enableFishIntegration = false; # manual acima pra controlar bindings
  };
  programs.bat.enable = true;
  programs.eza.enable = true;

  home.packages = with pkgs; [
    carapace
  ];
}
