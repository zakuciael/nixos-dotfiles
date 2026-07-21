{
  config,
  lib,
  pkgs,
  username,
  ...
}:
with lib;
let
  cfg = config.modules.dev.mitmproxy;
  user = "mitmproxy";
  dataDir = "/var/lib/mitmproxy";

  mitmproxy-ca-cert = pkgs.writeText "mitmproxy-ca-cert.pem" ''
    -----BEGIN CERTIFICATE-----
    MIIDNTCCAh2gAwIBAgIUW46Iah0kPiivavXRsQGviKO2HigwDQYJKoZIhvcNAQEL
    BQAwKDESMBAGA1UEAwwJbWl0bXByb3h5MRIwEAYDVQQKDAltaXRtcHJveHkwHhcN
    MjYwNzAyMDk1NzQwWhcNMzYwNjI5MDk1NzQwWjAoMRIwEAYDVQQDDAltaXRtcHJv
    eHkxEjAQBgNVBAoMCW1pdG1wcm94eTCCASIwDQYJKoZIhvcNAQEBBQADggEPADCC
    AQoCggEBAMSLYlwTgcRosYWd032iMVWjjn3oPvLIPzswhGF/AKjgNjR8W4jIuLtn
    KZDEcEShNTfYTdM8r/LntQhE/Ll2k4kgZIQ2VCS5rxisQKb4sl7zKXY7VcruIW/S
    jOdpQtyNt/B7PC+Er0LIpkwIGEvTkbotP4sbvS0F+PNEhQNK4PROjvBPRERpE0bk
    iKJwpaluPflx9Hoa/4lrU3NdaVbSpOHgtiwcNJPQvDjvlk+6gakZreboBnrsjqhw
    6Tj1HnsHlx+Bpm3Bb05PS2FJAxZWkfR9o5dvGTxX3gPqpQZenRecQHS8TQs2PZ0W
    gcflIr9CIZr9/cF7oPsDLOZyxkuHwykCAwEAAaNXMFUwDwYDVR0TAQH/BAUwAwEB
    /zATBgNVHSUEDDAKBggrBgEFBQcDATAOBgNVHQ8BAf8EBAMCAQYwHQYDVR0OBBYE
    FCVuX7HeRxRD/VIMDnUcGUCAjNoZMA0GCSqGSIb3DQEBCwUAA4IBAQACOh6mN5X+
    Mg6Lw27+k4Ytc4nhN6aTRvqwJPPB3m7r4xJd4u5gm2BcBRFt33ZJbRvs9is+iyuB
    7ioOAE0N9R3AAPy+Lq1Is6nDKJ0RYF/5E64Pb9YIyGmrJ6XUQ4sLCn6DsAebLLgv
    nwrZBqQbYIF/ZxoDDx9MF4CRebvZv6nfHVuO1YyYpagk6wPfrC0TWwJL8ahClFob
    IDnpD1jwXPptWyzj+tG/GpvH2Z7Pm3eJbz/h25Lq3+T+z/o23NIdVZoVUHNSApqp
    P+a+9RbAoIGtg7osjQV3+r9hZZN6EvjROy5C3t7hu++uPYJKLH7iUNdgR+K4fvkQ
    GTTGehGEJy11
    -----END CERTIFICATE-----
  '';
  mitmproxy-ca = pkgs.writeText "mitmproxy-ca.pem" ''
    -----BEGIN RSA PRIVATE KEY-----
    MIIEpQIBAAKCAQEAxItiXBOBxGixhZ3TfaIxVaOOfeg+8sg/OzCEYX8AqOA2NHxb
    iMi4u2cpkMRwRKE1N9hN0zyv8ue1CET8uXaTiSBkhDZUJLmvGKxApviyXvMpdjtV
    yu4hb9KM52lC3I238Hs8L4SvQsimTAgYS9ORui0/ixu9LQX480SFA0rg9E6O8E9E
    RGkTRuSIonClqW49+XH0ehr/iWtTc11pVtKk4eC2LBw0k9C8OO+WT7qBqRmt5ugG
    euyOqHDpOPUeeweXH4GmbcFvTk9LYUkDFlaR9H2jl28ZPFfeA+qlBl6dF5xAdLxN
    CzY9nRaBx+Uiv0Ihmv39wXug+wMs5nLGS4fDKQIDAQABAoIBAA6oEux+heb2zwTW
    8/kCmdQ4Of2DTq0TKBKgDRcqKItEtmDBRKAq0Qp56HHDvFgvKgVL643M5kANGFpm
    rplJUY+LFgPSpgFbxBtpE6R/7OlDZSb3HhrfxCg5wXPWTSaeU4ZVjPOW3Oz0LTaD
    71qO4JH2ItlwTEdUZ9qtlDpede+x3v4vjAB4g28Qg75xTL2tTht0aaxzxZGG4xYn
    3V/MlwHaRBfLtLYxCR4Znr/OV4qa/V85Az1zm74fAgdICa+v+XwE5CWOwlAkMojT
    ZEhl+PC3ZYvtCAjZ1UnTmigIMdfpJcyNYo6+fKjCbq1e0u5KXDUggs8JAbr/B97q
    efgcQhsCgYEA/Pdg/YduRoS5B+/mBXL59rgBOI7o35Dl6HLWi8ABMQFExKMHgpr1
    bqyCSjlPzdaalnQdwx0QW29/vQlhQelmmxLZHMNyPqakzrTg3WO0MzeHe5kqHcWW
    +RRu5N2xxWBWuLit1x7QdW7EazNchvI5xUpXsjPgn7p6b/a1nlbVz98CgYEAxubJ
    ehAgcP1dSNNQHTlKBqnjotxo0cZeHeJ4hSIlzoKYXe2hTAz3lyxWRkJyqey/OdW4
    PuPM5POZ7CIzAAUNlv75xhCDALIUqj6iookJyhyMyNv0ggxhkays/9k16mbtOq3F
    0YG6VOswLs77thCFPVcmpu5olPpoMsFc0GCOLfcCgYEAxESrXAnX5Z7UcPQQ4+lx
    R5s8V0WKKOujddaj34n5Yqw5Tteu3Aaepl/yNuSAppP7HQC6lsfWCRtZYLIGY71T
    fr4A9fAuk6138Wkljp/tEE/lLmCH7NGBcYAJCkl3xEwa/PdM6btewb5PZ11STOFj
    MU+c+waFIWjt1jD0eQWmnsECgYEAvITZyZunY/CAjhnbARffldlILICDyPAfHGwe
    lvD6rHUTPVORYaeYs+wOCaHJVE1UIdjzPIhlF0vcQ/dWJ1qius8IpjXYNLyU4Zdk
    RnFkme/dcDMp2GkrwQrNHeIePAE6MDesGxq+JOaVUIhWAwY9gxorRGULMsj0Iccr
    1UTu/ZkCgYEA0/GEHJS3ZA8WdXv2Tvitdw3lrT2oP+JfzoM8z0vT4+iseNUBUbme
    pzBaFc25M1ShFMZ3qN9OJaDNkgrUTwFJNB/i24J9MnXaTVV9wEcvDeutcs/ZkS8J
    54s7hE2eh8f2yKwSorQ5h4By95xPXdtSnvV+h+54hzVJJXi4bIk+XwE=
    -----END RSA PRIVATE KEY-----
    -----BEGIN CERTIFICATE-----
    MIIDNTCCAh2gAwIBAgIUW46Iah0kPiivavXRsQGviKO2HigwDQYJKoZIhvcNAQEL
    BQAwKDESMBAGA1UEAwwJbWl0bXByb3h5MRIwEAYDVQQKDAltaXRtcHJveHkwHhcN
    MjYwNzAyMDk1NzQwWhcNMzYwNjI5MDk1NzQwWjAoMRIwEAYDVQQDDAltaXRtcHJv
    eHkxEjAQBgNVBAoMCW1pdG1wcm94eTCCASIwDQYJKoZIhvcNAQEBBQADggEPADCC
    AQoCggEBAMSLYlwTgcRosYWd032iMVWjjn3oPvLIPzswhGF/AKjgNjR8W4jIuLtn
    KZDEcEShNTfYTdM8r/LntQhE/Ll2k4kgZIQ2VCS5rxisQKb4sl7zKXY7VcruIW/S
    jOdpQtyNt/B7PC+Er0LIpkwIGEvTkbotP4sbvS0F+PNEhQNK4PROjvBPRERpE0bk
    iKJwpaluPflx9Hoa/4lrU3NdaVbSpOHgtiwcNJPQvDjvlk+6gakZreboBnrsjqhw
    6Tj1HnsHlx+Bpm3Bb05PS2FJAxZWkfR9o5dvGTxX3gPqpQZenRecQHS8TQs2PZ0W
    gcflIr9CIZr9/cF7oPsDLOZyxkuHwykCAwEAAaNXMFUwDwYDVR0TAQH/BAUwAwEB
    /zATBgNVHSUEDDAKBggrBgEFBQcDATAOBgNVHQ8BAf8EBAMCAQYwHQYDVR0OBBYE
    FCVuX7HeRxRD/VIMDnUcGUCAjNoZMA0GCSqGSIb3DQEBCwUAA4IBAQACOh6mN5X+
    Mg6Lw27+k4Ytc4nhN6aTRvqwJPPB3m7r4xJd4u5gm2BcBRFt33ZJbRvs9is+iyuB
    7ioOAE0N9R3AAPy+Lq1Is6nDKJ0RYF/5E64Pb9YIyGmrJ6XUQ4sLCn6DsAebLLgv
    nwrZBqQbYIF/ZxoDDx9MF4CRebvZv6nfHVuO1YyYpagk6wPfrC0TWwJL8ahClFob
    IDnpD1jwXPptWyzj+tG/GpvH2Z7Pm3eJbz/h25Lq3+T+z/o23NIdVZoVUHNSApqp
    P+a+9RbAoIGtg7osjQV3+r9hZZN6EvjROy5C3t7hu++uPYJKLH7iUNdgR+K4fvkQ
    GTTGehGEJy11
    -----END CERTIFICATE-----
  '';

  mitmproxy-transparent-script = pkgs.writeShellApplication {
    name = "mitmtransparent";
    runtimeInputs = with pkgs; [
      mitmproxy
      iptables
      xdg-utils
    ];

    text = /* bash */ ''
      if [[ $EUID -ne 0 ]]; then
         echo "This script must be run as root"
         exit 1
      fi

      function enable_iptables {
        echo "> Enabling iptables routes"

        # IPv4
        iptables -t nat -A OUTPUT -p tcp -m owner ! --uid-owner ${user} --dport 80 -j REDIRECT --to-port 8080
        iptables -t nat -A OUTPUT -p tcp -m owner ! --uid-owner ${user} --dport 443 -j REDIRECT --to-port 8080
        # IPv6
        ip6tables -t nat -A OUTPUT -p tcp -m owner ! --uid-owner ${user} --dport 80 -j REDIRECT --to-port 8080
        ip6tables -t nat -A OUTPUT -p tcp -m owner ! --uid-owner ${user} --dport 443 -j REDIRECT --to-port 8080
      }

      function disable_iptables {
        echo "> Disabling iptables routes"

        # IPv4
        iptables -t nat -D OUTPUT -p tcp -m owner ! --uid-owner ${user} --dport 80 -j REDIRECT --to-port 8080
        iptables -t nat -D OUTPUT -p tcp -m owner ! --uid-owner ${user} --dport 443 -j REDIRECT --to-port 8080
        # IPv6
        ip6tables -t nat -D OUTPUT -p tcp -m owner ! --uid-owner ${user} --dport 80 -j REDIRECT --to-port 8080
        ip6tables -t nat -D OUTPUT -p tcp -m owner ! --uid-owner ${user} --dport 443 -j REDIRECT --to-port 8080
      }

      enable_iptables
      trap disable_iptables EXIT

      echo "> Running mitmproxy..."
      sudo -u ${user} mitmweb --mode transparent --showhost --set block_global=false --no-web-open-browser --anticache "$@"
      echo "> Stopping mitmproxy!"
    '';
  };
in
{
  options.modules.dev.mitmproxy = {
    enable = mkEnableOption "MITM Proxy (w/ transparent mode)";
  };

  config = mkIf cfg.enable {
    users = {
      users.${user} = {
        isSystemUser = true;
        home = dataDir;
        createHome = true;
        group = user;
      };
      groups.${user} = { };
    };

    # mitmproxy CA certs
    security.pki.certificateFiles = [ mitmproxy-ca-cert ];
    systemd.tmpfiles.rules = [
      "d ${dataDir}/ 755 ${user} ${user} - -"
      "d ${dataDir}/.mitmproxy/ 755 ${user} ${user} - -"

      "L+ ${dataDir}/.mitmproxy/mitmproxy-ca-cert.pem 755 ${user} ${user} - ${mitmproxy-ca-cert}"
      "L+ ${dataDir}/.mitmproxy/mitmproxy-ca.pem 755 ${user} ${user} - ${mitmproxy-ca}"
    ];

    home-manager.users.${username}.home.packages = [
      pkgs.mitmproxy
      mitmproxy-transparent-script
    ];
  };
}
