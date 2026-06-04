{ pkgs, ... }:

{
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    auto-optimise-store = true;
    download-buffer-size = 268435456; # 256 MiB
    http-connections = 50; # parallel connections (default 25)
    max-substitution-jobs = 16; # parallel substitutions (default 16)

    # Binary cache do kernel CachyOS
    substituters = [ "https://attic.xuyh0120.win/lantian" ];
    trusted-public-keys = [ "lantian:EeAUQ+W+6r7EtwnmYjeVwx5kOGEBpjlBfPlzGlTNvHc=" ];
  };

  # Varre lixo órfão do /nix/store por tempo (paths não referenciados há +7d).
  nix.gc = {
    automatic = true;
    dates = "daily";
    options = "--delete-older-than 7d";
  };

  # Poda por contagem: mantém só as 5 últimas gerações do sistema (bate com o
  # boot.loader.systemd-boot.configurationLimit). O nix.gc é por tempo e não
  # garante "manter N gerações", então isso complementa.
  systemd.services.nix-prune-generations = {
    description = "Poda o perfil do sistema pras 5 últimas gerações";
    serviceConfig.Type = "oneshot";
    script = "${pkgs.nix}/bin/nix-env --profile /nix/var/nix/profiles/system --delete-generations +5";
  };
  systemd.timers.nix-prune-generations = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "daily";
      Persistent = true;
    };
  };

  nixpkgs.config.allowUnfree = true;
}
