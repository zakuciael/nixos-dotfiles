{
  mkShell,
  sops,
  age,
  age-plugin-yubikey,
  nixfmt,
  nixd,
  statix,
  deadnix,
  ...
}:
mkShell {
  name = "nixos-dotfiles";
  nativeBuildInputs = [
    sops
    age
    age-plugin-yubikey
    nixfmt
    nixd
    statix
    deadnix
  ];
}
