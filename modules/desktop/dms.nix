{ inputs, pkgs, ... }:

{
  # Compositor Wayland
  programs.niri.enable = true;

  # Xwayland (system package only — session config is in home-manager)
  environment.systemPackages = [ pkgs.xwayland-satellite ];

  # Portais p/ screencast (PipeWire) e file pickers em apps Wayland/GTK
  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-gnome
      xdg-desktop-portal-gtk
    ];
    config = {
      niri.default = [ "gnome" "gtk" ];
      common.default = [ "gnome" "gtk" ];
      # O FileChooser do portal gnome é implementado pelo Nautilus, que não
      # está instalado; o do gtk usa o diálogo GTK e não depende dele.
      niri."org.freedesktop.impl.portal.FileChooser" = [ "gtk" ];
      common."org.freedesktop.impl.portal.FileChooser" = [ "gtk" ];
    };
  };

  # Greeter — via dank-greeter (o greeter saiu do DankMaterialShell no
  # upstream; o antigo services.displayManager.dms-greeter do dms passou a
  # apontar pra um asset que não existe mais e quebrava o boot).
  programs.dms-greeter = {
    enable = true;
    compositor.name = "niri";
  };

  # O greeter mudou de uid na migração (dms-greeter 994 -> greeter 993). O
  # estado antigo em /var/lib/dms-greeter/.cache fica órfão (uid 994) e o
  # greeter novo não consegue escrever nele — quebra a extração da UI
  # embutida ("mkdir .../.cache/dms-greeter-shell: permission denied"). Corrige
  # o dono recursivamente no boot, antes do greetd subir.
  systemd.tmpfiles.rules = [ "Z /var/lib/dms-greeter - greeter greeter - -" ];

  programs.dms-shell = {
    enable = true;
    package = inputs.dms.packages.${pkgs.stdenv.hostPlatform.system}.default;
    systemd = {
      enable = true;
      restartIfChanged = true;
    };
    # As opcoes enableVPN, enableDynamicTheming, enableAudioWavelength e
    # enableCalendarEvents foram removidas pelo DMS em 01/10/2026. Motivos:
    #   VPN e rede: o DMS detecta os backends em runtime.
    #   matugen (tema dinamico) e cava (wavelength): ja vem no ambiente padrao.
    #     Para tirar, usar programs.dms-shell.excludePackages.
    #   calendario: instalar um backend separado e escolher nas settings do DMS.
  };
}
