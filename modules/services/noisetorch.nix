{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    getExe
    optionalString
    mkIf
    mkEnableOption
    mkPackageOption
    mkOption
    types
    ;
  cfg = config.modules.services.noisetorch;
in
{
  options.modules.services.noisetorch = {
    enable = mkEnableOption "NoiseTorch microphone noise suppression";
    package = mkPackageOption pkgs "noisetorch" { };
    settings = {
      device = {
        id = mkOption {
          description = ''
            Pipewire device id of the source input.
            Can be found by using "noisetorch -l" command.

            If not specified the default pipewire source is used.
          '';
          example = "alsa_input.usb-0c76_USB_PnP_Audio_Device-00.mono-fallback";
          default = null;
          type = types.nullOr types.str;
        };
        unit = mkOption {
          description = ''
            Systemd unit corresponding to the desired microphone.
            This will make NoiseTorch service wait until the microphone is available before running.
            Can be found by using "systemctl list-units --type=device" command.
          '';
          example = "sys-devices-pci0000:00-0000:00:01.3-0000:02:00.0-usb1-1\\x2d6-1\\x2d6:1.0-sound-card2.device";
          type = types.str;
        };
      };
      threshold = mkOption {
        description = ''Voice activation threshold'';
        example = 55;
        default = -1;
        type = types.int;
      };
    };
  };

  config = mkIf (cfg.enable) {
    programs.noisetorch = {
      enable = true;
      package = cfg.package;
    };

    systemd.user.services."noisetorch" = {
      description = "NoiseTorch microphone noise suppression";
      after = [
        # cfg.settings.device.unit
        config.systemd.services.pipewire.name
      ];
      # requires = [ cfg.settings.device.unit ];
      wantedBy = [ "default.target" ];
      serviceConfig = {
        Type = "simple";
        RemainAfterExit = "yes";
        Restart = "on-failure";
        RestartSec = 3;
        ExecStart = ''
          ${getExe cfg.package} -i ${
            optionalString (cfg.settings.device.id != null) ''-s "${cfg.settings.device.id}"''
          } -t ${toString cfg.settings.threshold}
        '';
        ExecStop = ''${getExe cfg.package} -u'';

      };
    };
  };
}
