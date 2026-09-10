{ pkgs, ... }:

{
  hardware.logitech.wireless.enable = true;
  programs.solaar.enable = true;

  services.udev.packages = [ pkgs.solaar ];
}
