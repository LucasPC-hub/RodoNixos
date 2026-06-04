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

  home.enableNixpkgsReleaseCheck = false;

  # Stylix e Home Manager seguem o mesmo nixpkgs (unstable), então o aviso
  # de versão divergente é benigno. Desativa o check no nível do Home Manager
  # (o do nível NixOS já está em modules/desktop/stylix.nix).
  stylix.enableReleaseChecks = false;

  programs.git.enable = true;
  programs.git = {
    enable = true;
    settings.user = {
      name = "jaisla-rodojunior";
      email = "jaisla@rodojunior.com.br";
    };
    includes = [
      {
        condition = "gitdir:~/home-backup/development/pessoal/";
        contents = {
          user = {
            name = "jaislaataides";
            email = "jaisslaataidess@gmail.com";
          };
        };
      }
    ];
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
