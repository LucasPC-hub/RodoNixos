{ ... }:

{
  stylix.enable = true;
  stylix.autoEnable = false;
  stylix.base16Scheme = toString (builtins.path {
    path = ../../assets/themes/base-16/oled-lavender.yaml;
  });
  stylix.enableReleaseChecks = false;

  stylix.targets.console.enable = true;
  stylix.targets.gtk.enable = true;
}
