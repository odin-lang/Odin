{ pkgs ? import <nixpkgs> { } }:
let
  odin-unwrapped = pkgs.llvmPackages_11.stdenv.mkDerivation (rec {
    name = "odin-unwrapped";
    src = ./.;
    dontConfigure = true;
    nativeBuildInputs = [ pkgs.git ];
    buildPhase = ''
      make debug SHELL=${pkgs.llvmPackages_11.stdenv.shell}
    '';
    installPhase = ''
      mkdir -p $out/bin
      cp odin $out/bin/odin
      cp -r core $out/bin/core
    '';
  });
  path = builtins.map (path: path + "/bin") (with pkgs.llvmPackages_11; [
    bintools
    llvm
    clang
    lld
  ]);
in
pkgs.writeScriptBin "odin" ''
  #!${pkgs.llvmPackages_11.stdenv.shell} 
  PATH="${(builtins.concatStringsSep ":" path)}" exec ${odin-unwrapped}/bin/odin $@
''
