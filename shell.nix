{
  mkShell,
  sops,
  age,
  nixfmt-rfc-style,
  nixd,
  ...
}:
mkShell {
  name = "nixos-dotfiles";
  nativeBuildInputs = [
    sops
    age
    nixfmt-rfc-style
    nixd
  ];
}
