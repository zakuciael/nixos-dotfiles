{
  config,
  lib,
  pkgs,
  unstable,
  username,
  ...
}:
with lib;
with lib.my; let
  cfg = config.modules.dev.ides;
  avaiableIdes = builtins.listToAttrs (
    builtins.map (value: {
      name = value.pname;
      inherit value;
    })
    (with pkgs.jetbrains; [
      clion
      datagrip
      dataspell
      gateway
      goland
      idea-community
      idea-ultimate
      mps
      phpstorm
      pycharm-community
      pycharm-professional
      rider
      ruby-mine
      unstable.jetbrains.rust-rover
      webstorm
    ])
  );
in {
  options.modules.dev.ides = mkOption {
    description = "A list of JetBrains IDEs names to install";
    example = ["rust-rover" "webstorm"];
    default = [];
    type = with types; listOf (enum (builtins.attrNames avaiableIdes));
  };

  config = mkIf (cfg != []) {
    home-manager.users.${username} = {
      home.packages = builtins.map (name: avaiableIdes.${name}) cfg;
    };
  };
}
