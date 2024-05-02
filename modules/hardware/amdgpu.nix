{
  config,
  lib,
  ...
}:
with lib;
with lib.my; let
  cfg = config.modules.hardware.amdgpu;
in {
  options.modules.hardware.amdgpu = {
    enable = mkEnableOption "AMD GPU drivers";
  };

  config = mkIf (cfg.enable) {
    services.xserver.videoDrivers = mkIf config.services.xserver.enable ["amdgpu"];

    hardware.enableRedistributableFirmware = true;
    boot.initrd.kernelModules = ["amdgpu"];
  };
}
