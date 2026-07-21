{
  pkgs ? import <nixpkgs> { },
  ...
}:
pkgs.mkShell {
  name = "nixos-dotfiles";
  nativeBuildInputs = with pkgs; [
    sops
    age
    age-plugin-yubikey
    nixfmt
    nixd
    statix
    deadnix
  ];
}
