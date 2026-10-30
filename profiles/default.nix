# Configuration profiles (.mobileconfig), built into /etc/mobileconfig.
# macOS only installs profiles by hand: after a rebuild that changes one,
# `open /etc/mobileconfig/<name>.mobileconfig` and approve it in
# System Settings → General → Device Management.
{ lib, ... }:

let
  inherit (import ./lib.nix { inherit lib; }) mkProfile;

  # secrets.nix is gitignored (see secrets.example.nix). Without it, the
  # NextDNS parts are left out so a fresh clone still builds.
  secrets =
    if builtins.pathExists ../secrets.nix then
      import ../secrets.nix
    else
      lib.warn "secrets.nix missing: building profiles without NextDNS" { };
  nextdnsId = secrets.nextdnsId or null;
  hasNextdns = nextdnsId != null;

  # uBlock Origin bundled with Helium. On macOS, extension policy is read from
  # the domain <browser bundle id>.extensions.<extension id>.
  ublockId = "blockjmkbacgjkknlgpkjjiijinjdanf";

  profiles = {
    Restrictions = mkProfile {
      id = "com.yeginbay.profiles.restrictions";
      name = "Restrictions";
      locked = true;
      payloads.restrictions = {
        type = "com.apple.applicationaccess";
        settings = {
          allowUIAppInstallation = false;
          allowAppRemoval = false;
          allowWallpaperModification = false;
        };
      };
    };

    Helium = mkProfile {
      id = "com.yeginbay.profiles.helium";
      name = "Helium";
      description = "Secure DNS, no incognito/guest/new profiles, no search suggestions, and locked uBlock Origin YouTube filters in Helium.";
      payloads = {
        browser = {
          type = "net.imput.helium";
          name = "Helium Policies";
          settings = {
            # Close the ways around the extensions.
            IncognitoModeAvailability = 1; # disabled
            BrowserGuestModeEnabled = false;
            BrowserAddPersonEnabled = false;

            # No search suggestions in the address bar.
            SearchSuggestEnabled = false;
          }
          // lib.optionalAttrs hasNextdns {
            DnsOverHttpsMode = "secure";
            DnsOverHttpsTemplates = "https://dns.nextdns.io/${nextdnsId}";
          };
        };

        ublock = {
          type = "net.imput.helium.extensions.${ublockId}";
          name = "uBlock Origin Policies";
          settings = {
            disableDashboard = true;
            toOverwrite = {
              filters = [
                ''youtube.com##ytd-browse[page-subtype="home"] #contents''
                "youtube.com###secondary #related"
                "youtube.com##ytd-reel-shelf-renderer"
                "youtube.com##ytd-rich-shelf-renderer[is-shorts]"
                "youtube.com###comments"
                "||youtube.com/shorts^$doc"
              ];
              # Clears any "disable on this site" exceptions.
              trustedSiteDirectives = [ ];
            };
          };
        };
      };
    };
  }
  // lib.optionalAttrs hasNextdns {
    # System-wide encrypted DNS (originally from apple.nextdns.io).
    NextDNS = mkProfile {
      id = "com.yeginbay.profiles.nextdns";
      name = "NextDNS";
      description = "This profile enables NextDNS on all networks using the native Encrypted DNS feature.";
      locked = true;
      payloads.dnsSettings = {
        type = "com.apple.dnsSettings.managed";
        settings = {
          DNSSettings = {
            DNSProtocol = "HTTPS";
            ServerURL = "https://apple.dns.nextdns.io/${nextdnsId}";
          };
          OnDemandRules = [
            {
              # Captive portals and carrier voicemail break behind custom DNS.
              Action = "EvaluateConnection";
              ActionParameters = [
                {
                  DomainAction = "NeverConnect";
                  Domains = [
                    "captive.apple.com"
                    "3gppnetwork.org"
                    "dav.orange.fr"
                    "vvm.mobistar.be"
                    "vvm.mstore.msg.t-mobile.com"
                    "tma.vvm.mone.pan-net.eu"
                    "vvm.ee.co.uk"
                  ];
                }
              ];
            }
            { Action = "Connect"; }
          ];
          ProhibitDisablement = true;
        };
      };
    };
  };
in
{
  environment.etc = lib.mapAttrs' (
    name: text: lib.nameValuePair "mobileconfig/${name}.mobileconfig" { inherit text; }
  ) profiles;
}
