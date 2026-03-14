{ inputs, pkgs, ... }:

{
  # Compositor Wayland
  programs.niri.enable = true;

  # Greeter
  services.displayManager.dms-greeter = {
    enable = true;
    compositor.name = "niri";
    package = inputs.dms.packages.${pkgs.stdenv.hostPlatform.system}.default;
  };

  programs.dms-shell = {
    enable = true;
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
