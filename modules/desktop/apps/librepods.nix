{
  username,
  ...
}:
{
  programs.librepods.enable = true;
  users.users.${username}.extraGroups = [ "librepods" ];
  hardware.bluetooth.settings.General.DeviceID = "bluetooth:004C:0000:0000";
}
