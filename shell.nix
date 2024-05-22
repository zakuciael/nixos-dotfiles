{
  mkShell,
  sops,
  age,
  ...
}:
mkShell {
  name = "nixos-dotfiles";
  nativeBuildInputs = [sops age];
}
