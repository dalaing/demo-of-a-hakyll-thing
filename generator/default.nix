{ nixpkgs ? import <nixpkgs> {} }:
let
  inherit (nixpkgs) pkgs;
  haskellPackages = nixpkgs.haskellPackages.override {
    overrides = self: super: {
      blog-generator = self.callCabal2nix "blog-generator" ./. {};
    };
  };
in
  haskellPackages.blog-generator
