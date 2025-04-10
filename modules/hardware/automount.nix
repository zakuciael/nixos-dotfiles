{ username, ... }:
{
  config = {
    home-manager.users.${username} = {
      services.udiskie = {
        enable = true;
        automount = true;
      };
    };

    services = {
      udisks2 = {
        enable = true;
        mountOnMedia = false;
      };
      gvfs.enable = true;
    };
  };
}
