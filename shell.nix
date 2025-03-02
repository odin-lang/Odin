{ pkgs ? import <nixpkgs> {} }:
pkgs.mkShell {
  name = "odin";
  nativeBuildInputs = with pkgs; [
    git
    which
    clang_17
    llvmPackages_17.llvm
    llvmPackages_17.bintools
  ];
  shellHook="CXX=clang++";
}
