{ lib, ... }:

{
  programs.kitty = {
    enable = true;
    settings = {
      # Font
      font_size = 12;
      font_features = "none";

      # Window
      window_padding_width = 20;
      background_opacity = lib.mkForce "0.90";
      background_blur = 32;
      hide_window_decorations = true;
      confirm_os_window_close = 0;
      linux_display_server = "auto";

      # Audio
      enable_audio_bell = false;

      # Cursor
      cursor_shape = "block";
      cursor_blink_interval = 1;

      # Scrollback
      scrollback_lines = 3000;

      # Terminal
      copy_on_select = true;
      strip_trailing_spaces = "smart";
      shell_integration = "enabled";

      # Tabs
      tab_bar_edge = "top";
      tab_bar_style = "powerline";
      tab_powerline_style = "slanted";
      tab_bar_align = "left";
      tab_bar_min_tabs = 2;
      tab_bar_margin_width = "0.0";
      tab_bar_margin_height = "2.5 1.5";
      tab_bar_margin_color = "#070b14";
      tab_bar_background = "#070b14";
      active_tab_foreground = "#0b0f1a";
      active_tab_background = "#ff4e66";
      active_tab_font_style = "bold";
      inactive_tab_foreground = "#cbd5e1";
      inactive_tab_background = "#070b14";
      inactive_tab_font_style = "normal";
      tab_activity_symbol = " ● ";
      tab_title_template = "{fmt.fg.red}{bell_symbol}{activity_symbol}{fmt.fg.tab}{title[:30]}{title[30:] and '…'} [{index}]";
      active_tab_title_template = "{fmt.fg.red}{bell_symbol}{activity_symbol}{fmt.fg.tab}{title[:30]}{title[30:] and '…'} [{index}]";

      # Dank theme colors
      cursor = "#e6edf7";
      cursor_text_color = "#cbd5e1";
      foreground = "#e6edf7";
      background = "#070b14";
      selection_foreground = "#0b0f1a";
      selection_background = "#ff4e66";
      url_color = "#ff4e66";
      color0 = "#0b0f1a";
      color1 = "#ff3c3f";
      color2 = "#76ff4e";
      color3 = "#ffd83c";
      color4 = "#f62e46";
      color5 = "#760010";
      color6 = "#ff4e66";
      color7 = "#ffe9ec";
      color8 = "#a59496";
      color9 = "#ff7a7c";
      color10 = "#9fff83";
      color11 = "#ffe683";
      color12 = "#ff687c";
      color13 = "#ff8393";
      color14 = "#ffafba";
      color15 = "#fff6f7";
    };

    keybindings = {
      # Scrolling
      "shift+up" = "scroll_line_up";
      "shift+down" = "scroll_line_down";
      "shift+page_up" = "scroll_page_up";
      "shift+page_down" = "scroll_page_down";
      "ctrl+shift+page_up" = "scroll_to_prompt -1";
      "ctrl+shift+page_down" = "scroll_to_prompt 1";
      "shift+home" = "scroll_home";
      "shift+end" = "scroll_end";

      # Copy/Paste
      "ctrl+c" = "copy_to_clipboard";
      "ctrl+v" = "paste_from_clipboard";

      # Interrupt
      "ctrl+d" = "send_text all \\x03";

      # Font size
      "ctrl+plus" = "change_font_size all +1.0";
      "ctrl+minus" = "change_font_size all -1.0";
      "ctrl+0" = "change_font_size all 0";

      # Tabs
      "ctrl+t" = "new_tab";
      "ctrl+shift+n" = "new_window";
    };
  };
}
