{ ... }:

{
  stylix.enable = true;
  stylix.autoEnable = true;
  stylix.base16Scheme = toString (builtins.path {
    path = ../../assets/themes/base-16/oled-lavender.yaml;
  });
  stylix.enableReleaseChecks = false;

  # Desabilitar targets que conflitam com configs manuais
  stylix.targets.gnome.enable = false;
}
