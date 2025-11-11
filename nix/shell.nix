{pkgs}:
pkgs.clang_20.stdenv.mkDerivation {
  name = "odin";
  nativeBuildInputs = with pkgs; [
    git
    which
  ];
  shellHook = "CXX=clang++";
}
