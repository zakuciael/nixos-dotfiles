final: prev:
let
  inherit (final) fetchFromGitHub;
in
{
  # More up to date version of this https://github.com/ErikReider/SwayNotificationCenter/pull/262
  swaynotificationcenter = prev.swaynotificationcenter.overrideAttrs {
    src = fetchFromGitHub {
      owner = "zakuciael";
      repo = "SwayNotificationCenter";
      rev = "HEAD";
      hash = "sha256-I77SYSQZkhNWgCm1WMPJULYiqQEdH4g0zWhCX547CNs=";
    };
  };
}
