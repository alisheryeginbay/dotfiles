# Configuration profiles (.mobileconfig), built into /etc/mobileconfig.
# macOS only installs profiles by hand: after a rebuild that changes one,
# `open /etc/mobileconfig/<name>.mobileconfig` and approve it in
# System Settings → General → Device Management.
# Plain copies also go to ~/Library/Mobileconfig for dragging into Apple
# Configurator, which can't follow the /nix/store symlinks.
{ lib, config, ... }:

let
  inherit (import ./lib.nix { inherit lib; }) mkProfile;
  user = config.system.primaryUser;
  copies = "${config.users.users.${user}.home}/Library/Mobileconfig";

  # Cloudflare DNS over HTTPS, shared by the system and Helium.
  dohUrl = "https://cloudflare-dns.com/dns-query";

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
          allowEraseContentAndSettings = false;
          allowAppClips = false;
          allowEnterpriseAppTrust = false;
          # Stops Airplane Mode from the lock screen, which cuts off Find My
          allowLockScreenControlCenter = false;
          forceAutomaticDateAndTime = true;
          allowSpotlightInternetResults = false;
          # Only hosts with the supervision identity can pair
          allowHostPairing = false;
          # Profiles can still be pushed from Apple Configurator
          allowUIConfigurationProfileInstallation = false;
        };
      };
    };

    Helium = mkProfile {
      id = "com.yeginbay.profiles.helium";
      name = "Helium";
      description = "Cloudflare secure DNS, no incognito/guest/new profiles, no search suggestions, and locked uBlock Origin YouTube filters in Helium.";
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

            DnsOverHttpsMode = "secure";
            DnsOverHttpsTemplates = dohUrl;
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

    # System-wide encrypted DNS. Keeps the old NextDNS identifier so
    # installing it replaces that profile.
    DNS = mkProfile {
      id = "com.yeginbay.profiles.nextdns";
      name = "Cloudflare DNS";
      description = "Encrypted DNS through Cloudflare on all networks.";
      locked = true;
      payloads.dnsSettings = {
        type = "com.apple.dnsSettings.managed";
        settings = {
          DNSSettings = {
            DNSProtocol = "HTTPS";
            ServerURL = dohUrl;
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

  # Plain, user-owned copies of /etc/mobileconfig
  system.activationScripts.postActivation.text = lib.mkAfter ''
    install -d -o ${user} -m 755 "${copies}"
    rm -f "${copies}"/*.mobileconfig
    for f in /etc/mobileconfig/*.mobileconfig; do
      install -o ${user} -m 644 "$f" "${copies}"/
    done
  '';
}
