{
  mkShell,
  sops,
  age,
  age-plugin-yubikey,
  nixfmt,
  nixd,
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
  ];
}
