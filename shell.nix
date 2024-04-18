{
  pkgs ? import <nixpkgs> {},
  inputs,
  system,
  ...
}:
pkgs.mkShell {
  nativeBuildInputs = [
    inputs.nil.packages.${system}.default
    inputs.nixd.packages.${system}.default
    inputs.alejandra.defaultPackage.${system}
  ];
}
