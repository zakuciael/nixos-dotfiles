{ username, ... }:
{
  home-manager.users.${username}.programs.obsidian = {
    enable = true;
  };
}
