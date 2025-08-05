{ pkgs ? import <nixpkgs> {} }:
pkgs.mkShell {
  name = "odin";
  nativeBuildInputs = with pkgs; [
    git
    which
    clang_20
    llvmPackages_20.llvm
    llvmPackages_20.bintools
  ];
  shellHook="CXX=clang++";
}
