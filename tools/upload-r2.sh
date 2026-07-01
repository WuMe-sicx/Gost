#!/usr/bin/env bash
# Mirror gost release binaries + this repo's install files to a Cloudflare R2 bucket,
# in the flat layout gost.sh's R2_MIRROR expects.
#
# One-time setup:
#   1) Install rclone:            brew install rclone   (macOS)  |  apt install rclone  (Debian/Ubuntu)
#   2) Create an R2 API token:    Cloudflare dashboard > R2 > Manage API Tokens (Object Read & Write)
#   3) Configure an rclone remote (default name "r2"):
#        rclone config create r2 s3 \
#          provider=Cloudflare \
#          access_key_id=<ACCESS_KEY_ID> \
#          secret_access_key=<SECRET_ACCESS_KEY> \
#          endpoint=https://<ACCOUNT_ID>.r2.cloudflarestorage.com \
#          acl=private
#   4) Create the bucket in the dashboard and attach a public custom domain
#      (R2 > your bucket > Settings > Public access > Custom Domains).
#      That custom-domain base URL is what you set as R2_MIRROR in gost.sh.
#
# Usage:
#   tools/upload-r2.sh <bucket> [version] [rclone-remote]
#   version defaults to the latest ginuerzh/gost release; remote defaults to "r2".
set -euo pipefail

BUCKET="${1:?usage: $0 <bucket> [version] [rclone-remote]}"
VER="${2:-}"
REMOTE="${3:-r2}"
ARCHES=(amd64 arm64 386 armv7 armv6 armv5)

command -v rclone >/dev/null || { echo "rclone not found — see setup notes at the top of this script"; exit 1; }
command -v curl   >/dev/null || { echo "curl not found"; exit 1; }

if [ -z "$VER" ]; then
  VER=$(curl -fsSL https://api.github.com/repos/ginuerzh/gost/releases/latest \
        | grep tag_name | head -1 | sed -E 's/.*"v?([^"]+)".*/\1/')
fi
[ -n "$VER" ] || { echo "could not determine gost version"; exit 1; }

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

echo ">> gost version: $VER"
for a in "${ARCHES[@]}"; do
  f="gost_${VER}_linux_${a}.tar.gz"
  printf '   fetching %s ... ' "$f"
  if curl -fSL -o "$WORK/$f" "https://github.com/ginuerzh/gost/releases/download/v${VER}/${f}" 2>/dev/null; then
    echo "ok"
  else
    echo "skip (not published for this arch)"
    rm -f "$WORK/$f"
  fi
done

# install files served from the same flat namespace as the tarballs
cp "$REPO_DIR/gost.service" "$REPO_DIR/config.json" "$REPO_DIR/gost.sh" "$WORK/"

echo ">> uploading to ${REMOTE}:${BUCKET}/"
rclone copy --progress "$WORK" "${REMOTE}:${BUCKET}/"

echo ">> done. With a public custom domain https://<your-r2-domain> the files resolve as:"
echo "     https://<your-r2-domain>/gost_${VER}_linux_amd64.tar.gz"
echo "     https://<your-r2-domain>/gost.service  config.json  gost.sh"
echo ">> set  R2_MIRROR=\"https://<your-r2-domain>\"  in gost.sh to enable mirror downloads."
