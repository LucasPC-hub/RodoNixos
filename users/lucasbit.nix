{ ... }:

# Mesmo ambiente da laal: apps, Dolphin, atalhos e DankBar. O pessoal dela
# (git, contexto das IAs, aliases de projeto) fica em users/laal.nix.
{
  imports = [
    ./perfil-laal.nix
    ./programs/dankbar-laal.nix
  ];

  home.username = "lucasbit";
  home.homeDirectory = "/home/lucasbit";
  home.stateVersion = "25.05";

  # Identidade git dele: preencher quando tiver a conta.
  # programs.git.settings.user = {
  #   name = "";
  #   email = "";
  # };
}
