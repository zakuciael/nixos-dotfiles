{ username, ... }:
let
  mkLockedAttrs =
    attrs:
    attrs
    |> builtins.mapAttrs (
      _: v: {
        Value = v;
        Status = "locked";
      }
    );
  mkExtensionSettings =
    attrs:
    (
      attrs
      |> builtins.mapAttrs (
        id: val:
        val
        // {
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/${id}/latest.xpi";
          installation_mode = "force_installed";
        }
      )
    )
    // {
      # Block all addons except the ones specified in the config
      "*".installation_mode = "blocked";
    };
in
{
  home-manager.users.${username}.programs.zen-browser = {
    enable = true;
    languagePacks = [
      "pl"
      "en-US"
    ];

    policies = {
      DisableTelemetry = true;
      DisableFirefoxStudies = true;
      EnableTrackingProtection = {
        Value = true;
        Locked = true;
        Category = "standard";
      };
      DisablePocket = true;
      DisableFirefoxAccounts = true;
      DisableAccounts = true;
      DisableFirefoxScreenshots = true;
      OverrideFirstRunPage = "";
      OverridePostUpdatePage = "";
      DontCheckDefaultBrowser = true;
      # DisplayBookmarksToolbar = "never"; # alternatives: "always" or "newtab"
      # DisplayMenuBar = "default-off"; # alternatives: "always", "never" or "default-on"
      # SearchBar = "unified"; # alternative: "separate"
      SearchEngines = {
        Default = "Unduck";
        Add = [
          {
            Name = "Unduck";
            URLTemplate = "https://s.dunkirk.sh?q={searchTerms}";
            Method = "GET";
            IconURL = "https://s.dunkirk.sh/goose.gif";
            Alias = "unduck";
            Description = "A fast, local-first \"redirection engine\" for !bang users with a few extra features";
            SuggestURLTemplate = "https://duckduckgo.com/ac/?q={searchTerms}&type=list";
          }
        ];
      };

      Preferences = mkLockedAttrs {
      };

      ExtensionSettings = mkExtensionSettings {
        # uBlock Origin
        "uBlock0@raymondhill.net" = {
          private_browsing = true;
          default_area = "navbar";
        };
        # 1Password
        "{d634138d-c276-4fc8-924b-40a0ea21d284}" = {
          private_browsing = true;
          default_area = "navbar";
        };
        # Dark Reader
        "addon@darkreader.org" = {
          private_browsing = true;
          default_area = "navbar";
        };
      };
    };
  };
}
