{ inputs, pkgs, ... }:

{
  # Compositor Wayland
  programs.niri.enable = true;

  # Xwayland compatibility for X11 apps (Steam, etc.)
  environment.systemPackages = [ pkgs.xwayland-satellite ];
  environment.sessionVariables.DISPLAY = ":0";

  systemd.user.services.xwayland-satellite = {
    description = "Xwayland Satellite";
    wantedBy = [ "niri.service" ];
    after = [ "niri.service" ];
    serviceConfig = {
      ExecStart = "${pkgs.xwayland-satellite}/bin/xwayland-satellite :0";
      Restart = "on-failure";
      RestartSec = 3;
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
