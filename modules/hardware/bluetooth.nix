{ pkgs, ... }:

{
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
    settings = {
      General = {
        ControllerMode = "dual";
        FastConnectable = true;
        ConnectTimeout = 60;
      };
      Policy = {
        AutoEnable = true;
      };
    };
  };

  # Fixes pra desconexão e autosuspend
  boot.extraModprobeConfig = ''
    options bluetooth disable_ertm=1
    options btusb enable_autosuspend=0
    options btusb reset=1
  '';

  services.dbus.packages = with pkgs; [ bluez ];

  environment.systemPackages = with pkgs; [ bluez ];
}
