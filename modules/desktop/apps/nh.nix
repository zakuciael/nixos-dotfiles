{unstable, ...}: {
  programs.nh = {
    enable = true;
    package = unstable.nh;
    clean = {
      enable = true;
      dates = "weekly";
      extraArgs = "--keep 10 --keep-since 7d";
    };
  };
}
