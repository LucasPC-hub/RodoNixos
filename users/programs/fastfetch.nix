{ ... }:

{
  programs.fastfetch = {
    enable = true;
    settings = {
      logo = {
        source = "~/nixos/assets/icons/nix-lavender.png";
        padding = {
          top = 2;
          left = 3;
        };
        width = 40;
      };
      modules = [
        "break"
        {
          type = "custom";
          format = "──────────────────────Hardware──────────────────────";
        }
        {
          type = "cpu";
          key = " ";
          showPeCoreCount = true;
          keyColor = "33";
        }
        {
          type = "gpu";
          key = " 󰍛";
          keyColor = "33";
        }
        {
          type = "memory";
          key = " ";
          keyColor = "33";
        }
        {
          type = "custom";
          format = "────────────────────────────────────────────────────";
        }
        "break"
        {
          type = "custom";
          format = "──────────────────────Software──────────────────────";
        }
        {
          type = "os";
          key = " 󱄅";
          keyColor = "yellow";
        }
        {
          type = "kernel";
          key = " ";
          keyColor = "yellow";
        }
        {
          type = "packages";
          key = " ";
          keyColor = "yellow";
        }
        {
          type = "wm";
          key = " 󰇄";
          keyColor = "33";
        }
        {
          type = "lm";
          key = " 󰍂";
          keyColor = "33";
        }
        {
          type = "terminal";
          key = " ";
          keyColor = "33";
        }
        {
          type = "shell";
          key = " ";
          keyColor = "33";
        }
        {
          type = "custom";
          format = "────────────────────────────────────────────────────";
        }
        "break"
        {
          type = "custom";
          format = "────────────────────Uptime / Age────────────────────";
        }
        {
          type = "command";
          key = "  OS Age ";
          keyColor = "33";
          text = "birth_install=$(stat -c %W /); current=$(date +%s); time_progression=$((current - birth_install)); days_difference=$((time_progression / 86400)); echo $days_difference days";
        }
        {
          type = "uptime";
          key = "  Uptime ";
          keyColor = "33";
        }
        {
          type = "custom";
          format = "────────────────────────────────────────────────────";
        }
        "break"
      ];
    };
  };
}
