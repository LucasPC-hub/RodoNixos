{ modulesPath, pkgs, lib, ... }:

# Config da ISO instaladora do RodoNixos. Base: installation-cd-minimal do
# nixpkgs + rede (NetworkManager) + git + o comando rodo-install.
#
# Build da ISO:
#   nix build .#nixosConfigurations.rodo-installer.config.system.build.isoImage
#   -> ./result/iso/rodonixos-installer.iso  (grave num pendrive com dd/Ventoy)

{
  imports = [
    (modulesPath + "/installer/cd-dvd/installation-cd-minimal.nix")
  ];

  # A ISO minimal habilita wpa_supplicant; troco por NetworkManager (nmtui pra
  # conectar wifi na hora do install, que precisa de rede pra baixar do cache).
  networking.wireless.enable = lib.mkForce false;
  networking.networkmanager.enable = true;

  # nixos-install precisa de flakes
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  environment.systemPackages = with pkgs; [
    git
    nixos-install-tools
  ];

  services.getty.helpLine = lib.mkForce ''

      RodoNixos installer. Conecte a rede (nmtui) e rode:  sudo rodo-install
  '';

  isoImage.isoName = lib.mkForce "rodonixos-installer.iso";

  # A ISO é efêmera; ok fixar a versão da base do live.
  system.stateVersion = "25.05";
}
