{ pkgs ? import <nixpkgs> {} }:
pkgs.mkShell {
  name = "odin";
  nativeBuildInputs = with pkgs; [
    git
    which
    clang_18
    llvmPackages_18.llvm
    llvmPackages_18.bintools
  ];
  shellHook="CXX=clang++";
}
