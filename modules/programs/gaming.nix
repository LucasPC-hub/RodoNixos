{ pkgs, ... }:

{
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
    localNetworkGameTransfers.openFirewall = true;
    gamescopeSession.enable = true;
  };

  hardware.steam-hardware.enable = true;

  environment.systemPackages = with pkgs; [
    gamescope
    protonplus
    lutris
  ];
}
