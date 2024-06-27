{...}: {
  config = {
    services.udisks2 = {
      enable = true;
      mountOnMedia = false;
    };

    services.devmon.enable = true;
    services.gvfs.enable = true;
  };
}
