{
  pkgs,
  lib,
  config,
  ...
}:
with lib;
with lib.my; let
  cfg = config.modules.hardware.sound;
in {
  options.modules.hardware.sound = {
    enable = mkEnableOption "Enable sound";
    driver = mkOption {
      type = types.str;
      default = "pipewire";
      example = "pipewire";
      description = "Select sound driver";
    };
  };

  config = mkIf (cfg.enable) {
    sound.enable = true;
    security.rtkit.enable = true;

    hardware.pulseaudio = rec {
      enable = cfg.driver == "pulseaudio";
      support32Bit = enable;
    };

    services.pipewire = let
      pipewireEnable = cfg.driver == "pipewire";
    in {
      enable = pipewireEnable;
      alsa.enable = pipewireEnable;
      alsa.support32Bit = pipewireEnable;
      pulse.enable = pipewireEnable;
    };
  };
}
