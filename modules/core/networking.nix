{ ... }:

{
  # hostName é definido em cada host
  networking.networkmanager.enable = true;
  networking.firewall.enable = true;

  networking.extraHosts = ''
    10.1.1.28 DSK-281
  '';
}
