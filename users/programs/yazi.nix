{ pkgs, ... }:

{
  programs.yazi = {
    enable = true;
    enableFishIntegration = true; # wrapper 'y' que faz cd ao sair
    shellWrapperName = "y";

    settings = {
      manager = {
        show_hidden = true;
        sort_by = "natural";
        sort_sensitive = false;
        sort_reverse = false;
        sort_dir_first = true;
        linemode = "size";
        show_symlink = true;
        scrolloff = 5;
      };

      preview = {
        wrap = "yes";
        tab_size = 2;
        max_width = 1000;
        max_height = 1000;
        image_quality = 90;
      };

      opener = {
        edit = [
          { run = ''vim "$@"''; block = true; for_ = "unix"; }
        ];
        open = [
          { run = ''xdg-open "$@"''; orphan = true; for_ = "unix"; }
        ];
        reveal = [
          { run = ''xdg-open "$(dirname "$@")"''; orphan = true; for_ = "unix"; }
        ];
      };
    };

    keymap = {
      manager.prepend_keymap = [
        # Navegacao rapida
        { on = [ "g" "h" ]; run = "cd ~";           desc = "Home"; }
        { on = [ "g" "c" ]; run = "cd ~/.config";    desc = "Config"; }
        { on = [ "g" "d" ]; run = "cd ~/Downloads";  desc = "Downloads"; }
        { on = [ "g" "D" ]; run = "cd ~/Documents";  desc = "Documents"; }
        { on = [ "g" "n" ]; run = "cd ~/RodoNixos";  desc = "NixOS config"; }

        # Abrir shell no diretorio atual
        { on = [ "!" ]; run = "shell \"$SHELL\" --block --confirm"; desc = "Shell aqui"; }

        # Criar arquivo/diretorio
        { on = [ "a" ]; run = "create"; desc = "Criar arquivo/diretorio"; }

        # Compactar/extrair
        { on = [ "C" ]; run = "shell 'tar czf \"$1.tar.gz\" \"$@\"' --block --confirm"; desc = "Compactar"; }
        { on = [ "X" ]; run = "shell 'for f in \"$@\"; do extract \"$f\"; done' --block --confirm"; desc = "Extrair"; }

        # Chmod
        { on = [ "c" "m" ]; run = "shell 'chmod +x \"$@\"' --confirm"; desc = "Tornar executavel"; }
      ];
    };

    theme = {
      # Catppuccin Mocha
      manager = {
        cwd = { fg = "#94e2d5"; };

        # Hovered
        hovered = { fg = "#1e1e2e"; bg = "#89b4fa"; };
        preview_hovered = { underline = true; };

        # Find
        find_keyword = { fg = "#f9e2af"; italic = true; };
        find_position = { fg = "#f5c2e7"; bg = "reset"; italic = true; };

        # Marker
        marker_copied = { fg = "#a6e3a1"; bg = "#a6e3a1"; };
        marker_cut = { fg = "#f38ba8"; bg = "#f38ba8"; };
        marker_selected = { fg = "#89b4fa"; bg = "#89b4fa"; };
        marker_marked = { fg = "#cba6f7"; bg = "#cba6f7"; };

        # Tab
        tab_active = { fg = "#1e1e2e"; bg = "#89b4fa"; };
        tab_inactive = { fg = "#cdd6f4"; bg = "#45475a"; };
        tab_width = 1;

        # Count
        count_copied = { fg = "#1e1e2e"; bg = "#a6e3a1"; };
        count_cut = { fg = "#1e1e2e"; bg = "#f38ba8"; };
        count_selected = { fg = "#1e1e2e"; bg = "#89b4fa"; };

        # Border
        border_symbol = "│";
        border_style = { fg = "#7f849c"; };

        # Syntax highlighting theme for previews
        syntect_theme = "";
      };

      mode = {
        normal_main = { fg = "#1e1e2e"; bg = "#89b4fa"; bold = true; };
        normal_alt = { fg = "#89b4fa"; bg = "#313244"; };

        select_main = { fg = "#1e1e2e"; bg = "#a6e3a1"; bold = true; };
        select_alt = { fg = "#a6e3a1"; bg = "#313244"; };

        unset_main = { fg = "#1e1e2e"; bg = "#f2cdcd"; bold = true; };
        unset_alt = { fg = "#f2cdcd"; bg = "#313244"; };
      };

      status = {
        separator_open = "";
        separator_close = "";
        separator_style = { fg = "#45475a"; bg = "#45475a"; };

        # Mode
        mode_normal = { fg = "#1e1e2e"; bg = "#89b4fa"; bold = true; };
        mode_select = { fg = "#1e1e2e"; bg = "#a6e3a1"; bold = true; };
        mode_unset = { fg = "#1e1e2e"; bg = "#f2cdcd"; bold = true; };

        # Progress
        progress_label = { fg = "#cdd6f4"; bold = true; };
        progress_normal = { fg = "#89b4fa"; bg = "#313244"; };
        progress_error = { fg = "#f38ba8"; bg = "#313244"; };

        # Permissions
        permissions_t = { fg = "#89b4fa"; };
        permissions_r = { fg = "#f9e2af"; };
        permissions_w = { fg = "#f38ba8"; };
        permissions_x = { fg = "#a6e3a1"; };
        permissions_s = { fg = "#7f849c"; };
      };

      input = {
        border = { fg = "#89b4fa"; };
        title = {};
        value = {};
        selected = { reversed = true; };
      };

      pick = {
        border = { fg = "#89b4fa"; };
        active = { fg = "#cba6f7"; };
        inactive = {};
      };

      completion = {
        border = { fg = "#89b4fa"; };
        active = { bg = "#313244"; };
        inactive = {};
      };

      tasks = {
        border = { fg = "#89b4fa"; };
        title = {};
        hovered = { underline = true; };
      };

      which = {
        mask = { bg = "#313244"; };
        cand = { fg = "#94e2d5"; };
        rest = { fg = "#9399b2"; };
        desc = { fg = "#cba6f7"; };
        separator = " → ";
        separator_style = { fg = "#585b70"; };
      };

      help = {
        on = { fg = "#cba6f7"; };
        run = { fg = "#94e2d5"; };
        desc = { fg = "#9399b2"; };
        hovered = { bg = "#313244"; bold = true; };
        footer = { fg = "#313244"; bg = "#cdd6f4"; };
      };

      filetype = {
        rules = [
          # Media
          { mime = "image/*"; fg = "#94e2d5"; }
          { mime = "video/*"; fg = "#f9e2af"; }
          { mime = "audio/*"; fg = "#f9e2af"; }

          # Archives
          { mime = "application/zip"; fg = "#cba6f7"; }
          { mime = "application/gzip"; fg = "#cba6f7"; }
          { mime = "application/x-tar"; fg = "#cba6f7"; }
          { mime = "application/x-bzip*"; fg = "#cba6f7"; }
          { mime = "application/x-7z-compressed"; fg = "#cba6f7"; }
          { mime = "application/x-rar"; fg = "#cba6f7"; }

          # Documents
          { mime = "application/pdf"; fg = "#f38ba8"; }
          { mime = "application/doc"; fg = "#89b4fa"; }

          # Fallbacks
          { name = "*"; fg = "#cdd6f4"; }
          { name = "*/"; fg = "#89b4fa"; bold = true; }
        ];
      };
    };
  };
}
