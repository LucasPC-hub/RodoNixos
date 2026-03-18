{ ... }:

{
  stylix.enable = true;
  stylix.autoEnable = false;
  stylix.base16Scheme = toString (builtins.path {
    path = ../../assets/themes/base-16/oled-lavender.yaml;
  });
  stylix.enableReleaseChecks = false;

  # Só o console/TTY
  stylix.targets.console.enable = true;
}
