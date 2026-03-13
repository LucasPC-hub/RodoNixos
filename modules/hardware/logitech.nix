{ pkgs, ... }:

{
  hardware.logitech.wireless = {
    enable = true;
    enableGraphical = true;
  };

  services.udev.packages = [ pkgs.solaar ];

  environment.systemPackages = with pkgs; [ solaar ];
}
