{ pkgs, lib, ... }:

{
  imports = [
    ./programs/kitty.nix
    ./programs/fish.nix
    ./programs/starship.nix
    ./programs/obs.nix
    ./programs/fastfetch.nix
    ./programs/vscode.nix
    ./programs/yazi.nix
    ./programs/dms-config.nix
    ./programs/niri-sync.nix
  ];

  programs.git = {
    enable = true;
    userName = "laralimamota";
    userEmail = "llmotadev@gmail.com";
  };
  programs.home-manager.enable = true;

  # direnv + nix-direnv: carrega dev shells automaticamente ao entrar na pasta
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  dconf.settings = {
    "org/gnome/desktop/interface" = {
      gtk-theme = "adw-gtk3-dark";
      color-scheme = lib.mkForce "prefer-dark";
    };
  };
}
