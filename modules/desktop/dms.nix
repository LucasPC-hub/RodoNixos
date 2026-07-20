{ inputs, pkgs, ... }:

{
  # Compositor Wayland
  programs.niri.enable = true;

  # Xwayland (system package only — session config is in home-manager)
  environment.systemPackages = [ pkgs.xwayland-satellite ];

  # Greeter — via dank-greeter (o greeter saiu do DankMaterialShell no
  # upstream; o antigo services.displayManager.dms-greeter do dms passou a
  # apontar pra um asset que não existe mais e quebrava o boot).
  programs.dms-greeter = {
    enable = true;
    compositor.name = "niri";
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
