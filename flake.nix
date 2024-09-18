{
  description = "General Purpose Configuration for macOS and NixOS";
  inputs = {
    # Core
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    # Home Manager
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # System Management
    darwin = {
      url = "github:LnL7/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-on-droid = {
      url = "github:nix-community/nix-on-droid/release-24.05";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };
    system-manager = {
      url = "github:numtide/system-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Security
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Development tools
    pre-commit-hooks = {
      url = "github:cachix/git-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixvim = {
      url = "github:nix-community/nixvim";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # macOS-specific
    nix-homebrew = {
      url = "github:zhaofengli-wip/nix-homebrew";
    };
    homebrew-bundle = {
      url = "github:homebrew/homebrew-bundle";
      flake = false;
    };
    homebrew-core = {
      url = "github:homebrew/homebrew-core";
      flake = false;
    };
    homebrew-cask = {
      url = "github:homebrew/homebrew-cask";
      flake = false;
    };
    nikitabobko-aerospace = {
      url = "github:nikitabobko/homebrew-tap";
      flake = false;
    };

    # Linux-specific
    nixgl = {
      url = "github:guibou/nixGL";
    };

    # NixOS
    nixos-hardware = {
      url = "github:NixOS/nixos-hardware/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # CLI
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Browser
    firefox-addons = {
      url = "gitlab:rycee/nur-expressions?dir=pkgs/firefox-addons";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Add the apple-fonts input
    apple-fonts = {
      url = "git+https://codeberg.org/adamcstephens/apple-fonts.nix";
      inputs.nixpkgs.follows = "nixpkgs";
      # Optionally, specify the branch if it's not the default
      # url = "git+https://codeberg.org/adamcstephens/apple-fonts.nix?ref=main";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      pre-commit-hooks,
      sops-nix,
      treefmt-nix,
      nixgl,
      disko,
      nixvim,
      darwin,
      nixos-hardware,
      nix-homebrew,
      nix-on-droid,
      rust-overlay,
      homebrew-core,
      homebrew-cask,
      homebrew-bundle,
      nikitabobko-aerospace,
      ...
    }@inputs:
    let
      inherit (self) outputs;
      user = "geoffrey";
      systems.linux = [
        "aarch64-linux"
        "x86_64-linux"
      ];
      systems.darwin = [
        "aarch64-darwin"
        "x86_64-darwin"
      ];
      systems.android = [
        "aarch64-linux"
        # Nix-on-Droid does not support the following systems
        # "armv7-linux"
        # "armv8-linux"
        # "x86_64-linux"
      ];
      allowed-unfree-packages = [
        "lmstudio"
        "nvidia"
        "mendeley"
      ];
      systems.supported = systems.linux ++ systems.darwin ++ systems.android;

      forAllSystems = f: nixpkgs.lib.genAttrs systems.supported f;
      lib =
        nixpkgs.lib
        // home-manager.lib
        // {
          isLinux = system: builtins.elem system systems.linux;
          isDarwin = system: builtins.elem system systems.darwin;
          isAndroid = system: builtins.elem system systems.android;
          forAllSystems = forAllSystems;
        };
      sharedConfig = import ./nix/modules/shared/default.nix;
      pkgsFor =
        system:
        import nixpkgs {
          inherit system;
          config = {
            allowUnfree = true;
            allowBroken = true;
            allowInsecure = false;
            allowUnsupportedSystem = true;
            allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) allowed-unfree-packages;
          };
          overlays =
            let
              path = ./nix/overlays;
              overlayFiles =
                with builtins;
                filter (n: match ".*\\.nix" n != null || pathExists (path + ("/" + n + "/default.nix"))) (
                  attrNames (readDir path)
                );
            in
            builtins.trace "Loading overlays: ${builtins.toString overlayFiles}" (
              map (n: import (path + ("/" + n))) overlayFiles
            )
            ++ [
              (final: prev: {
                nixus = self.packages.${system}.nixus;
              })
            ]
            ++ lib.optional (lib.isAndroid system) (
              final: prev: {
                nix-on-droid = nix-on-droid.packages.${system};
              }
            )
            ++ lib.optional (lib.isAndroid system) nix-on-droid.overlays.default
            ++ lib.optional (lib.isAndroid system) sops-nix.overlays.default
            ++ lib.optional (lib.isLinux system) nixgl.overlay;
        };
      treefmtEval = forAllSystems (
        system: treefmt-nix.lib.evalModule (pkgsFor system) ./nix/formatter/default.nix
      );
    in
    {

      ##############################
      # Packages Configuration
      ##############################
      packages = forAllSystems (
        system:
        let
          pkgs = pkgsFor system;
        in
        {
          nixus = import ./nix/apps/nixus {
            inherit
              system
              pkgs
              rust-overlay
              lib
              nix-on-droid
              ;
          };
          hosts = pkgs.writeShellScriptBin "hosts" (builtins.readFile ./scripts/print_hosts.sh);
        }
      );

      ##############################
      # Apps Configuration
      ##############################
      apps = forAllSystems (
        system:
        let
          pkgs = pkgsFor system;
          nixusApp = self.packages.${system}.nixus;
        in
        {
          default = {
            type = "app";
            program = "${nixusApp}/bin/nixus";
          };
          switch = {
            type = "app";
            program = "${pkgs.writeScriptBin "switch" (builtins.readFile ./nix/apps/switch.sh)}/bin/switch";
          };
          nixus = {
            type = "app";
            program = "${nixusApp}/bin/nixus";
          };
          check = {
            type = "app";
            program = "${pkgs.writeShellScriptBin "run-checks" ''
              ${self.checks.${system}.pre-commit-check.shellHook}
              pre-commit run --all-files
            ''}/bin/run-checks";
          };
        }
      );

      ##############################
      # Darwin Configuration
      ##############################
      darwinConfigurations = nixpkgs.lib.genAttrs systems.darwin (
        system:
        darwin.lib.darwinSystem {
          inherit system;
          pkgs = pkgsFor system;
          modules = [
            home-manager.darwinModules.home-manager
            nix-homebrew.darwinModules.nix-homebrew
            nixvim.nixDarwinModules.nixvim
            {
              nix-homebrew = {
                inherit user;
                enable = true;
                taps = {
                  "homebrew/homebrew-core" = homebrew-core;
                  "nikitabobko/homebrew-tap" = nikitabobko-aerospace;
                  "homebrew/homebrew-cask" = homebrew-cask;
                  "homebrew/homebrew-bundle" = homebrew-bundle;
                };
                mutableTaps = false;
                autoMigrate = true;
              };
            }
            ./nix/hosts/darwin

          ];
          specialArgs = {
            inherit inputs self user;
          };
        }
      );

      ##############################
      # NixOS Configuration
      ##############################
      nixosConfigurations = nixpkgs.lib.genAttrs systems.linux (
        system:
        nixpkgs.lib.nixosSystem {
          inherit system;
          pkgs = pkgsFor system;
          specialArgs = {
            inherit inputs self user;
          };
          modules = [
            disko.nixosModules.disko
            home-manager.nixosModules.home-manager
            sops-nix.nixosModules.sops
            nixos-hardware.nixosModules.common-cpu-intel
            nixos-hardware.nixosModules.common-gpu-nvidia-nonprime
            ./nix/hosts/nixos/configuration.nix
            {
              home-manager = {
                backupFileExtension = "nixus.bak";
                sharedModules = [
                  nixvim.homeManagerModules.nixvim
                  inputs.sops-nix.homeManagerModules.sops
                  ./nix/packages/shared/shell-aliases
                ];
                useGlobalPkgs = true;
                extraSpecialArgs = {
                  inherit inputs self user;
                };
                # useUserPackages = true;
                users.${user} =
                  {
                    self,
                    config,
                    pkgs,
                    inputs,
                    user,
                    ...
                  }:
                  {
                    imports = [ ./nix/modules/nixos/home-manager.nix ];
                  };
              };
            }
            ./nix/hosts/nixos
          ];
        }
      );

      ##############################
      # Nix-on-Droid Configuration
      ##############################
      nixOnDroidConfigurations.default = nix-on-droid.lib.nixOnDroidConfiguration {
        pkgs = pkgsFor "aarch64-linux";
        modules = [
          ./nix/hosts/android
          {
            networking.hosts = {
              "100.116.122.19" = [ "artemis.tail" ];
              "100.64.241.11" = [ "crazy-diamond.tail" ];
              "100.92.233.30" = [ "crazy-phone.tail" ];
              "100.111.132.9" = [ "dodo-iphone.tail" ];
              "100.91.33.40" = [ "google-chromecast.tail" ];
              "100.98.196.120" = [ "nimbus.tail" ];
              "100.78.156.17" = [ "pioneer.tail" ];
              "100.112.193.127" = [ "voyager.tail" ];
            };
          }

          {
            home-manager.extraSpecialArgs = {
              inherit self inputs user;
            };
            home-manager.sharedModules = [
              inputs.sops-nix.homeManagerModules.sops
              #nixvim.homeManagerModules.nixvim
            ];
          }
        ];
      };

      ##############################
      # Home Configuration
      ##############################
      homeConfigurations = forAllSystems (
        system:
        lib.homeManagerConfiguration {
          pkgs = pkgsFor system;
          modules =
            [
              inputs.sops-nix.homeManagerModules.sops
              #nixvim.homeManagerModules.nixvim
              ./nix/packages/shared/shell-aliases
            ]
            ++ lib.filter (m: m != null) [
              (if lib.isDarwin system then ./nix/modules/darwin/default.nix else null)
              (if lib.isLinux system then ./nix/modules/linux/default.nix else null)
            ];
          extraSpecialArgs = {
            inherit
              self
              inputs
              user
              ;
          };
        }
      );

      ##############################
      # Checks Configuration
      ##############################
      checks =
        nixpkgs.lib.mapAttrs (name: config: config.activationPackage) self.homeConfigurations
        // forAllSystems (system: {
          pre-commit-check = pre-commit-hooks.lib.${system}.run {
            src = ./.;
            hooks = {
              nixfmt-rfc-style.enable = true;
              beautysh.enable = true;
              commitizen.enable = true;
            };
          };
        });

      ##############################
      # Formatter Configuration
      ##############################
      formatter = forAllSystems (system: treefmtEval.${system}.config.build.wrapper);

      ##############################
      # Dev Shell Configuration
      ##############################
      devShells = forAllSystems (system: {
        default = (pkgsFor system).mkShell {
          buildInputs = self.checks.${system}.pre-commit-check.enabledPackages;
          shellHook = self.checks.${system}.pre-commit-check.shellHook;
        };
      });
    };
}
