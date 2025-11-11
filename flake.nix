{
  description = "Odin language flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = {
    self, # Needed for proper caching
    nixpkgs,
    flake-utils,
  }:
    flake-utils.lib.eachDefaultSystem (
      system: let
        pkgs = nixpkgs.legacyPackages.${system};
      in {
        packages = {
          default = pkgs.callPackage ./nix {
            inherit pkgs;
          };
        };
        devShells = {
          default = pkgs.callPackage ./nix/shell.nix {
            inherit pkgs;
          };
        };
      }
    );
}
