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

  # Greeter
  services.displayManager.dms-greeter = {
    enable = true;
    compositor.name = "niri";
    package = inputs.dms.packages.${pkgs.stdenv.hostPlatform.system}.default;
  };

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
