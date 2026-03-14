{ pkgs, ... }:

{
  services.printing.enable = true;
  services.printing.drivers = [ pkgs.cups-filters ];
}
