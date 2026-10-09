#!/bin/sh
# Create the self-signed code-signing identity that darwin.nix uses to sign
# kanata, so its Input Monitoring permission survives kanata updates.
# Run once as an admin: sudo sh scripts/create-kanata-cert.sh
set -eu
NAME=kanata-local
KEYCHAIN=/Library/Keychains/System.keychain

[ "$(id -u)" -eq 0 ] || { echo "run with sudo" >&2; exit 1; }

if security find-certificate -c "$NAME" "$KEYCHAIN" >/dev/null 2>&1; then
  echo "$NAME already exists in $KEYCHAIN"
  exit 0
fi

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
cd "$TMP"

# macOS's LibreSSL, whose PKCS#12 output `security import` understands.
/usr/bin/openssl req -x509 -newkey rsa:2048 -nodes -days 7300 \
  -subj "/CN=$NAME" -keyout key.pem -out cert.pem \
  -addext "keyUsage=critical,digitalSignature" \
  -addext "extendedKeyUsage=critical,codeSigning" \
  -addext "basicConstraints=critical,CA:false"
PASS=$(/usr/bin/openssl rand -hex 16)
/usr/bin/openssl pkcs12 -export -inkey key.pem -in cert.pem -name "$NAME" \
  -out id.p12 -passout "pass:$PASS"

# -T lets codesign use the key without a prompt during activation.
security import id.p12 -k "$KEYCHAIN" -P "$PASS" -T /usr/bin/codesign
security add-trusted-cert -d -r trustRoot -p codeSign -k "$KEYCHAIN" cert.pem

security find-identity -v -p codesigning "$KEYCHAIN" | grep "$NAME"
echo "created $NAME"
