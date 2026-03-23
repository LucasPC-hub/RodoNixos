{ ... }:

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

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
  };

  nixpkgs.config.allowUnfree = true;
}
