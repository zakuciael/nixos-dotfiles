{
  pkgs ? import <nixpkgs> {},
  inputs,
  system,
  ...
}:
pkgs.mkShell {
  nativeBuildInputs = with pkgs; [nixd inputs.alejandra.defaultPackage.${system}];
}
