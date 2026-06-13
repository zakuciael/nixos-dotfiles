{ ... }:
{
  # TODO: Setup bridge for VMs

  networking.nameservers = [
    "1.1.1.1"
    "1.0.0.1"
  ];

  services.resolved = {
    enable = true;
    settings.Resolve = {
      DNSOverTLS = true;
      DNSSEC = true;
      Domains = [ "~." ];
      FallbackDNS = [
        "1.1.1.1"
        "1.0.0.1"
      ];
    };
  };
}
