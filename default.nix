{ nixpkgs ? import <nixpkgs> {} }:
let
  inherit (nixpkgs) pkgs;
  blog-generator = import ./generator { inherit nixpkgs; };

  content = nixpkgs.stdenv.mkDerivation {
    name = "blog-content";
    src = ./content;

    buildPhase = ''
      export LANG=en_US.UTF-8
      export LOCALE_ARCHIVE=/run/current-system/sw/lib/locale/locale-archive
      site build
    '';

    installPhase = ''
      mkdir -p $out
      cp -r _site/* $out/
    '';

    phases = ["unpackPhase" "buildPhase" "installPhase"];

    buildInputs = [blog-generator pkgs.imagemagick pkgs.ghostscript pkgs.glibcLocales];
  };
in
  content
