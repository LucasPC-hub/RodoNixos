# Gerado automaticamente por nixos-generate-config
# Substitua este arquivo pelo output de:
#   nixos-generate-config --show-hardware-config
{ config, lib, modulesPath, ... }:

{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  # TODO: Cole aqui o conteúdo do hardware-configuration.nix
  # gerado durante a instalação do NixOS
}
