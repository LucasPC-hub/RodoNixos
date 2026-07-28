    {
  description = "RodoNixos - NixOS com kernel CachyOS";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    # CachyOS kernel (não sobrescrever o nixpkgs dele)
    nix-cachyos-kernel.url = "github:xddxdd/nix-cachyos-kernel/release";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixvim = {
      url = "github:nix-community/nixvim";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    quickshell = {
      url = "git+https://git.outfoxxed.me/quickshell/quickshell";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    dms = {
      url = "github:AvengeMedia/DankMaterialShell/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Greeter: o upstream tirou o greeter do DankMaterialShell e moveu pra
    # este repo separado. `programs.dms-greeter` (dank-greeter) substitui o
    # antigo `services.displayManager.dms-greeter` do dms.
    dank-greeter = {
      url = "github:AvengeMedia/dank-greeter";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    claude-code = {
      url = "github:sadjow/claude-code-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    claude-desktop = {
      # Pinned to 1.7196.3 (2026-05-19). Newer commits bump to 1.8089.1,
      # whose minified bundle breaks the tray-menu patcher in
      # scripts/patches/tray.sh ("Failed to extract tray menu function
      # name"). Unpin once upstream fixes the regex for the new bundle.
      url = "github:aaddrick/claude-desktop-debian/ba2846c8b3e99ac35563e6c2184dd999b19bbc95";
    };

    dsearch = {
      # Pinned: newer revs ship a stale Go vendorHash upstream (hash mismatch
      # in dsearch-go-modules). Unpin once upstream fixes their vendorHash.
      url = "github:AvengeMedia/danksearch/18591ecaa4b87acb222391f9aedd2fbbef9c087f";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    helium-browser = {
      url = "github:oxcl/nix-flake-helium-browser";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    t3code = {
      url = "path:./flakes/t3code";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    cmux = {
      url = "github:LucasPC-hub/lcmux";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    stylix = {
      url = "github:danth/stylix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Gerenciamento de segredos cifrados versionados no repo (age).
    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Particionamento declarativo (usado só pelo host base + rodo-install).
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, ... }@inputs:
  let
    system = "x86_64-linux";

    mkHost = { hostPath, users, extraModules ? [] }: nixpkgs.lib.nixosSystem {
      inherit system;
      specialArgs = { inherit inputs; };
      modules = [
        hostPath

        # Overlay para desabilitar doc do python (bug no nixpkgs)
        {
          nixpkgs.overlays = [
            (final: prev: {
              python312 = prev.python312.overrideAttrs (old: {
                passthru = old.passthru // {
                  doc = final.emptyDirectory;
                };
              });
              # nixpkgs trava o bun em 1.3.13; o omp exige >=1.3.14. Bump pro
              # prebuilt oficial (só troca o zip, não compila).
              bun = prev.bun.overrideAttrs (_old: rec {
                version = "1.3.14";
                src = final.fetchurl {
                  url = "https://github.com/oven-sh/bun/releases/download/bun-v${version}/bun-linux-x64.zip";
                  hash = "sha256-lR7iruhV8IWVruxiJSJqKY0/6oOj3NZGXAnLzN9+hI8=";
                };
              });
              quickshell = inputs.quickshell.packages.${system}.default;
              # nixpkgs bumpou libdisplay-info pra 0.4.0, mas o niri 26.04
              # ainda usa a crate libdisplay-info-sys 0.3.0 (exige < 0.4.0).
              # Aponta o niri pro libdisplay-info_0_2 (0.2.0), que satisfaz.
              niri = prev.niri.overrideAttrs (old: {
                buildInputs = map
                  (p: if (p.pname or "") == "libdisplay-info"
                      then final.libdisplay-info_0_2
                      else p)
                  old.buildInputs;
              });
            })
            inputs.claude-desktop.overlays.default
          ];
        }

        # Editor de vídeo open source
        ({ pkgs, ... }: {
          environment.systemPackages = [ pkgs.kdePackages.kdenlive ];
        })

        inputs.dms.nixosModules.default
        inputs.dank-greeter.nixosModules.default
        inputs.stylix.nixosModules.stylix
        inputs.agenix.nixosModules.default
        inputs.home-manager.nixosModules.default
        {
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            extraSpecialArgs = { inherit inputs; };
            users = builtins.mapAttrs (_name: path: import path) users;
          };
        }
      ] ++ extraModules;
    };
  in
  {
    nixosConfigurations = {
      # ISO instaladora auto-provisionadora. Build:
      #   nix build .#nixosConfigurations.rodo-installer.config.system.build.isoImage
      rodo-installer = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = { inherit inputs; self = inputs.self; };
        modules = [
          ./modules/install/installer.nix
          ./modules/install/rodo-install.nix
        ];
      };

      # Host BASE — template do padrão da empresa. Copie hosts/base + use
      # users/rodouser.nix pra provisionar máquinas novas.
      base = mkHost {
        hostPath = ./hosts/base;
        users = { rodouser = ./users/rodouser.nix; };
      };

      # >>> RODO-INSTALL-HOSTS (não remova: âncora do rodo-install) <<<

      rodolucas = mkHost {
        hostPath = ./hosts/rodolucas;
        users = { lucasp = ./users/lucasp.nix; };
      };

      laal = mkHost {
        hostPath = ./hosts/laal;
        users = { laal = ./users/laal.nix; };
      };

      rodojaisla = mkHost {
        hostPath = ./hosts/rodojaisla;
        users = { jaisla = ./users/jaisla.nix; };
        extraModules = [
          ({ pkgs, ... }: {
            services.postgresql = {
              enable = true;
              ensureDatabases = [ "jaisla" ];
              ensureUsers = [
                {
                  name = "jaisla";
                  ensureDBOwnership = true;
                }
              ];
              authentication = pkgs.lib.mkOverride 10 ''
                local all all              trust
                host  all all 127.0.0.1/32 trust
                host  all all ::1/128      trust
              '';
            };
          })
        ];
      };
    };
  };
}
