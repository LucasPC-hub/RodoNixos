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
      url = "github:AvengeMedia/DankMaterialShell/stable";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.quickshell.follows = "quickshell";
    };

    claude-code = {
      url = "github:sadjow/claude-code-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    claude-desktop = {
      url = "github:aaddrick/claude-desktop-debian";
    };

    dsearch = {
      url = "github:AvengeMedia/danksearch";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake";
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
  };

  outputs = { nixpkgs, ... }@inputs:
  let
    system = "x86_64-linux";

    mkHost = { hostPath, users }: nixpkgs.lib.nixosSystem {
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
              quickshell = inputs.quickshell.packages.${system}.default;
            })
            inputs.claude-desktop.overlays.default
          ];
        }

        inputs.dms.nixosModules.default
        inputs.stylix.nixosModules.stylix
        inputs.home-manager.nixosModules.default
        {
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            extraSpecialArgs = { inherit inputs; };
            users = builtins.mapAttrs (_name: path: import path) users;
          };
        }
      ];
    };
  in
  {
    nixosConfigurations = {
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
      };
    };
  };
}
