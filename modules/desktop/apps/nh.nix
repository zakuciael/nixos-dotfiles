{
  lib,
  unstable,
  ...
}:
with lib; {
  programs.nh = {
    enable = true;
    package = unstable.nh;
    clean = {
      enable = true;
      dates = "daily";
      extraArgs = "--keep 10 --keep-since 7d";
    };
  };

  systemd.timers.nh-clean.timerConfig = mkForce {
    OnBootSec = "15m";
    OnUnitActiveSec = "1d";
    Persistent = true;
  };
}
