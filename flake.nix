{
  description = "NixOs config builder";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-23.11";

    flake-utils.url = "github:numtide/flake-utils";

    nixosgen = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, nixosgen, flake-utils, ...}: flake-utils.lib.eachDefaultSystem (system:
   let
    pkgs = import nixpkgs { inherit system; };

    built_system = nixosgen.nixosGenerate {
      inherit pkgs;
      format = "vm-nogui";
      modules = [ ./base.nix ./module.nix ];
    };
  in {
    apps.default = {
      type = "app";
      program = let
        exec = pkgs.writeShellScript "start_system" "${built_system}/bin/run-srv-builder-vm";
      in "${exec}";
    };
  });
}
