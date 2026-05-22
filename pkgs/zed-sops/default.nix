{
  buildZedRustExtension,
  fetchFromGitHub,
}:
buildZedRustExtension (finalAttrs: {
  name = "sops";
  version = "3693a25fd3e282aa7298885c1a8299433d0ee96e";

  src = fetchFromGitHub {
    owner = "meesk";
    repo = "zed-sops";
    rev = finalAttrs.version;
    hash = "sha256-WnY1qm8KqLonvHr03aZLPwge2mm4whpYcV5DqFkwXI8=";
  };

  cargoHash = "sha256-1R6fkl8HkySxsrtAyKQE4kLCcJDLn80d7O6cabUIG/0=";
})
