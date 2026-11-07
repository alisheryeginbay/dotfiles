# Blocks X through /etc/hosts outside the open hours below. /etc/hosts wins
# over any DNS server, so this holds with any DNS setting or Mullvad on.
# A root daemon re-checks every minute, so hand edits to /etc/hosts get undone.
{ pkgs, lib, ... }:

let
  # Local time, HHMM; start inclusive, end exclusive; can't cross midnight.
  openHours = [
    {
      start = "2000";
      end = "2100";
    }
  ];

  # No wildcards in /etc/hosts, so each subdomain is listed.
  domains = [
    "x.com"
    "www.x.com"
    "api.x.com"
    "mobile.x.com"
    "pro.x.com"
    "twitter.com"
    "www.twitter.com"
    "api.twitter.com"
    "mobile.twitter.com"
    "t.co"
    "abs.twimg.com"
    "pbs.twimg.com"
    "video.twimg.com"
  ];

  entries = pkgs.writeText "focus-hosts" (
    lib.concatMapStrings (d: "0.0.0.0 ${d}\n:: ${d}\n") domains
  );

  isOpen = lib.concatMapStringsSep " || " (
    w: ''[[ ! "$now" < "${w.start}" && "$now" < "${w.end}" ]]''
  ) openHours;

  script = pkgs.writeShellScript "focus-block" ''
    set -eu
    hosts=/private/etc/hosts
    begin="# focus-block-start"
    end="# focus-block-end"

    now=$(/bin/date +%H%M)
    if ${isOpen}; then open=1; else open=0; fi

    tmp=$(/usr/bin/mktemp /private/etc/hosts.focus.XXXXXX)
    trap '/bin/rm -f "$tmp"' EXIT
    {
      /usr/bin/sed "/^$begin\$/,/^$end\$/d" "$hosts"
      if [ "$open" = 0 ]; then
        echo "$begin"
        cat ${entries}
        echo "$end"
      fi
    } > "$tmp"

    if ! /usr/bin/cmp -s "$tmp" "$hosts"; then
      /bin/chmod 644 "$tmp"
      /bin/mv "$tmp" "$hosts"
      /usr/bin/dscacheutil -flushcache
      /usr/bin/killall -HUP mDNSResponder || true
      echo "$(/bin/date): open=$open"
    fi
  '';
in
{
  launchd.daemons.focus-block.serviceConfig = {
    ProgramArguments = [ "${script}" ];
    RunAtLoad = true;
    StartInterval = 60;
    StandardOutPath = "/Library/Logs/focus-block.log";
    StandardErrorPath = "/Library/Logs/focus-block.log";
  };
}
