{
  username,
  ...
}:
{
  programs.librepods.enable = true;
  users.users.${username}.extraGroups = [ "librepods" ];
}
