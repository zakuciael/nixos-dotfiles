{
  lib,
  unstable,
  username,
  ...
}:
with lib;
with lib.my; {
  # TODO: Automatic account creation from secrets
  home-manager.users.${username} = {
    programs.thunderbird = {
      enable = true;
      package = unstable.thunderbird;
      profiles = {
        "default" = {
          isDefault = true;
        };
      };
    };
  };
}
