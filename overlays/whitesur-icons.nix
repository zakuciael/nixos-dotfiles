{lib, ...}:
with lib; {
  # TODO: Remove when https://github.com/vinceliuice/WhiteSur-icon-theme/pull/293 will be upstreamed to nixpkgs
  pkgs = singleton (final: prev: {
    whitesur-icon-theme = prev.whitesur-icon-theme.overrideAttrs {
      src = final.fetchFromGitHub {
        owner = "zakuciael";
        repo = "WhiteSur-icon-theme";
        rev = "90a6787061bfb5a630f4295eda59d1058cf30da5";
        hash = "sha256-S10HagxiZxbyhsmzS12X7SJOF9YqWKuhZqfjcc0mog8=";
      };
    };
  });
}
