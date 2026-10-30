{ lib }:
let
  # A UUID derived from the identifier: rebuilding gives the same UUID, so a
  # reinstalled profile replaces the old one instead of piling up.
  uuid =
    s:
    let
      h = lib.toUpper (builtins.hashString "sha256" s);
      sub = builtins.substring;
    in
    "${sub 0 8 h}-${sub 8 4 h}-${sub 12 4 h}-${sub 16 4 h}-${sub 20 12 h}";
in
{
  # Builds the plist text of a configuration profile. Each payload only lists
  # its type and settings; the Payload* boilerplate is filled in here.
  mkProfile =
    {
      id,
      name,
      description ? "",
      locked ? false, # can't be removed in System Settings
      payloads,
    }:
    lib.generators.toPlist { escape = true; } (
      {
        PayloadType = "Configuration";
        PayloadIdentifier = id;
        PayloadUUID = uuid id;
        PayloadVersion = 1;
        PayloadDisplayName = name;
        PayloadDescription = description;
        PayloadScope = "System";
        PayloadContent = lib.mapAttrsToList (
          sub: p:
          {
            PayloadType = p.type;
            PayloadIdentifier = "${id}.${sub}";
            PayloadUUID = uuid "${id}.${sub}";
            PayloadVersion = 1;
            PayloadDisplayName = p.name or name;
          }
          // p.settings
        ) payloads;
      }
      // lib.optionalAttrs locked { PayloadRemovalDisallowed = true; }
    );
}
