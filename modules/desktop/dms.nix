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
    enableSystemMonitoring = true;
    enableVPN = true;
    enableDynamicTheming = true;
    enableAudioWavelength = true;
    enableCalendarEvents = true;
    enableClipboardPaste = true;
  };
}
