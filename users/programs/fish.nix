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
      # Catppuccin Mocha Colors
      #============================================
      set -g catppuccin_rosewater "f5e0dc"
      set -g catppuccin_flamingo "f2cdcd"
      set -g catppuccin_pink "f5c2e7"
      set -g catppuccin_mauve "cba6f7"
      set -g catppuccin_red "f38ba8"
      set -g catppuccin_maroon "eba0ac"
      set -g catppuccin_peach "fab387"
      set -g catppuccin_yellow "f9e2af"
      set -g catppuccin_green "a6e3a1"
      set -g catppuccin_teal "94e2d5"
      set -g catppuccin_sky "89dceb"
      set -g catppuccin_sapphire "74c7ec"
      set -g catppuccin_blue "89b4fa"
      set -g catppuccin_lavender "b4befe"
      set -g catppuccin_text "cdd6f4"
      set -g catppuccin_subtext1 "bac2de"
      set -g catppuccin_subtext0 "a6adc8"
      set -g catppuccin_overlay2 "9399b2"
      set -g catppuccin_overlay1 "7f849c"
      set -g catppuccin_overlay0 "6c7086"
      set -g catppuccin_surface2 "585b70"
      set -g catppuccin_surface1 "45475a"
      set -g catppuccin_surface0 "313244"
      set -g catppuccin_base "1e1e2e"
      set -g catppuccin_mantle "181825"
      set -g catppuccin_crust "11111b"

      # Fish colors - Catppuccin Mocha
      set -g fish_color_normal $catppuccin_text
      set -g fish_color_command $catppuccin_blue
      set -g fish_color_keyword $catppuccin_mauve
      set -g fish_color_quote $catppuccin_green
      set -g fish_color_redirection $catppuccin_pink
      set -g fish_color_end $catppuccin_peach
      set -g fish_color_error $catppuccin_red
      set -g fish_color_param $catppuccin_lavender
      set -g fish_color_comment $catppuccin_overlay0
      set -g fish_color_selection --background=$catppuccin_surface0
      set -g fish_color_search_match --background=$catppuccin_surface0
      set -g fish_color_operator $catppuccin_sky
      set -g fish_color_escape $catppuccin_pink
      set -g fish_color_autosuggestion $catppuccin_overlay0
      set -g fish_pager_color_progress $catppuccin_overlay0
      set -g fish_pager_color_prefix $catppuccin_blue
      set -g fish_pager_color_completion $catppuccin_text
      set -g fish_pager_color_description $catppuccin_overlay0

      set -gx CLICOLOR 1
      set -gx LS_COLORS 'di=34:ln=35:so=32:pi=33:ex=31:bd=34;46:cd=34;43:su=30;41:sg=30;46:tw=30;42:ow=30;43'

      #============================================
      # FZF - Catppuccin Mocha
      #============================================
      set -gx FZF_DEFAULT_OPTS "
        --height 40%
        --layout=reverse
        --border
        --inline-info
        --color=bg+:#313244,bg:#1e1e2e,spinner:#f5e0dc,hl:#f38ba8
        --color=fg:#cdd6f4,header:#f38ba8,info:#cba6f7,pointer:#f5e0dc
        --color=marker:#f5e0dc,fg+:#cdd6f4,prompt:#cba6f7,hl+:#f38ba8
      "
      set -gx FZF_CTRL_T_OPTS "--preview 'bat --color=always --style=numbers --line-range=:500 {}' --preview-window right:50%:wrap"
      set -gx FZF_ALT_C_OPTS "--preview 'eza --tree --level=2 --color=always {} 2>/dev/null' --preview-window right:50%"

      #============================================
      # CARAPACE
      #============================================
      set -gx CARAPACE_BRIDGES 'zsh,fish,bash,inshellisense'
      carapace _carapace fish | source

      #============================================
      # Atuin (com fzf)
      #============================================
      set -gx ATUIN_NOBIND true
      atuin init fish | source

      # Busca histórico do fish via fzf
      function _fish_fzf_history
        set -l output (history | fzf --height 40% --layout=default --border --query (commandline -b))
        if test -n "$output"
          commandline -r $output
        end
        commandline -f repaint
      end

      bind \cr _fish_fzf_history
      bind up _fish_fzf_history

      #============================================
      # Desabilita kitty keyboard protocol
      #============================================
      printf '\e[>4;0m'

      #============================================
      # fifc - fzf tab completion com preview
      #============================================
      set -g fifc_fd_opts --hidden
      set -g fifc_bat_opts --style=numbers

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
    fishPlugins.fzf-fish
    fishPlugins.fifc
  ];
}
