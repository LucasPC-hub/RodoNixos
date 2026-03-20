{ pkgs, ... }:

{
  imports = [
    ./programs/kitty.nix
    ./programs/fish.nix
    ./programs/starship.nix
    ./programs/nixvim.nix
    ./programs/obs.nix
    ./programs/fastfetch.nix
    ./programs/vscode.nix
  ];

  programs.git.enable = true;
  programs.home-manager.enable = true;

  # direnv + nix-direnv: carrega dev shells automaticamente ao entrar na pasta
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };
}
