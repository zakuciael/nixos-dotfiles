{lib, ...}:
with lib; {
  pkgs = singleton (final: prev: {
    # TODO: Remove when https://github.com/getsops/sops/pull/1465 is merged
    sops = final.buildGoModule {
      inherit (prev.sops.drvAttrs) pname version subPackages ldflags;
      inherit (prev.sops) meta;
      src = prev.fetchFromGitHub {
        owner = "Mic92";
        repo = "sops";
        rev = "a077fbf103edd823ca7be8dddd01f4f1703da40e";
        hash = "sha256-9r9nylzD6aKtfGLOjtzGJJelUllxcC7Fzh4A9Wc2OA4=";
      };

      vendorHash = "sha256-DeeQodjVu9QtT0p+zCnVbGSAdSLLt8Y9SiOvKuaQ730=";
    };
  });
}
