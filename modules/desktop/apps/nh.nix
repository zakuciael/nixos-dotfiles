{...}: {
  programs.nh = {
    enable = true;
    clean = {
      enable = true;
      dates = "weekly";
      extraArgs = "--keep 10 --keep-since 7d";
    };
  };
}
