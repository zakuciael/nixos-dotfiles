{
  device ? throw "device not set",
  ...
}:
{
  disko.devices = {
    disk.sd_card = {
      inherit device;

      type = "disk";
      content = {
        type = "gpt";
        partitions = {
          shared = {
            size = "150G";
            alignment = 1; # Set sector alignment to align to physical sectors.
            content = {
              type = "filesystem";
              format = "ntfs";
              extraArgs = [
                "-L"
                "Shared"
                "-Q" # Fast format
              ];
            };
          };
          steamdeck = {
            size = "100%";
            content = {
              type = "filesystem";
              format = "ext4";
              extraArgs = [
                "-L"
                "SteamDeck"
              ];
            };
          };
        };
      };
    };
  };
}
