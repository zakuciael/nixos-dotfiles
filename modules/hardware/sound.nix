{
  config,
  lib,
  ...
}:
with lib;
with lib.my; let
  cfg = config.modules.hardware.sound;
in {
  options.modules.hardware.sound = {
    enable = mkEnableOption "sound driver";
    driver = mkOption {
      description = "Select sound driver";
      example = "pulseaudio";
      default = "pipewire";
      type = types.str;
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
