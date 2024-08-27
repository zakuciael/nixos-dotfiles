{
  lib,
  pkgs,
  ...
}:
with lib; {
  networking = {
    # TODO: Setup bridge for VMs
    nameservers = ["1.1.1.1" "8.8.8.8" "8.8.4.4"];
    networkmanager = {
      enable = true;
      dispatcherScripts = [
        {
          type = "basic";

          source = let
            src = pkgs.writeShellApplication {
              name = "wifi-wired-exclusive";
              runtimeInputs = with pkgs; [networkmanager];
              text = ''
                export LC_ALL=C

                enable_disable_wifi () {
                  local result
                  result=$(nmcli dev | grep "ethernet" | grep -w "connected")
                  if [ -n "$result" ]; then
                    nmcli radio wifi off
                  else
                    nmcli radio wifi on
                  fi
                }

                if [ "$2" = "up" ]; then
                  enable_disable_wifi
                fi

                if [ "$2" = "down" ]; then
                  enable_disable_wifi
                fi
              '';
            };
          in "${getBin src}";
        }
      ];
    };
  };
}
