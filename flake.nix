{
  description = "NixOs config builder";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-23.11";

    flake-utils.url = "github:numtide/flake-utils";

    nixosgen = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager/release-23.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, nixosgen, flake-utils, home-manager, ...}:
  flake-utils.lib.eachDefaultSystem (system:
   let
    pkgs = import nixpkgs { inherit system; };
    lib = pkgs.lib;

    built_system = nixosgen.nixosGenerate {
      inherit pkgs;
      format = "vm-nogui";
      modules = [ ./base.nix ./module.nix home-manager.nixosModules.home-manager ];
    };
  in {
    packages = let
      version = "v1.0.0-RC2";
      src = pkgs.fetchFromGitHub {
        owner = "mealie-recipes";
        repo = "mealie";
        rev = version;
        sha256 = "sha256-/sht8s0Nap6TdYxAqamKj/HGGV21/8eYCuYzpWXRJCE=";
      };
    in rec {
      backend = import ./mealie-backend.nix { inherit lib pkgs version src; };
      frontend = import ./mealie-frontend.nix { inherit lib pkgs version src; };
      test = let 
      in pkgs.writeShellScript "test-mealie" ''
        export PYTHONPATH="${backend.pythonPath}:${backend}/lib/${backend.python3.libPrefix}/site-packages"
        export STATIC_FILES="${frontend}"
      '';
    };

    apps.default = {
      type = "app";
      program = let
        exec = pkgs.writeShellScript "start_system" "${built_system}/bin/run-srv-builder-vm";
      in "${exec}";
    };
  });
}
