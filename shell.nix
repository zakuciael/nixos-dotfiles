{
  pkgs ? import <nixpkgs> {},
  inputs,
  system,
  ...
}:
pkgs.mkShell {
  nativeBuildInputs = [inputs.nixd.packages.${system}.default inputs.alejandra.defaultPackage.${system}];
}
