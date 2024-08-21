{...}: {
  networking = {
    # TODO: Setup bridge for VMs
    nameservers = ["1.1.1.1" "8.8.8.8" "8.8.4.4"];
    hostName = "laptop";

    useDHCP = true;
  };
}
