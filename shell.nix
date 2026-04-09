{
  mkShell,
  sops,
  age,
  age-plugin-yubikey,
  nixfmt-rfc-style,
  nixd,
  ...
}:
mkShell {
  name = "nixos-dotfiles";
  nativeBuildInputs = [
    sops
    age
    age-plugin-yubikey
    nixfmt-rfc-style
    nixd
  ];
}
