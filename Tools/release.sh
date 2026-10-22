#!/usr/bin/env bash
# Build leKVM and put it in the release archive.
#
#   Tools/release.sh            build, then drop the .app in the archive
#   Tools/release.sh --no-build use what is already in dist/
#
# The archive is a flat folder of "<App> <date>.zip", one zip per release, each
# holding the .app at its root. A second release on the same day gets -a, then
# -b, and so on — the first of the day carries no suffix.
#
# ditto, not zip: an Electron bundle is full of symlinks inside Frameworks, and
# zip follows them. That both bloats the archive and breaks the app.
set -euo pipefail
cd "$(dirname "$0")/.."

# Where releases go. The committed default stays inside the repo so this file
# needs to know nothing about anyone's filesystem — a personal path in published
# code is just someone's folder layout on display. Point LEKVM_RELEASES wherever
# you keep them, or set it once in Tools/release.local.env, which is gitignored.
# Precedence: an explicitly exported LEKVM_RELEASES wins, then the local file,
# then the in-repo default. Sourcing the file first would let it silently
# override the variable you just set on the command line.
_env_dest="${LEKVM_RELEASES:-}"
[ -f Tools/release.local.env ] && . Tools/release.local.env
DEST="${_env_dest:-${LEKVM_RELEASES:-dist/releases}}"
APP=$(node -p "require('./package.json').productName")
BUNDLE="dist/mac-arm64/$APP.app"

if [ "${1:-}" != "--no-build" ]; then
  echo "==> building"
  npm run build
fi

if [ ! -d "$BUNDLE" ]; then
  echo "no $BUNDLE — run without --no-build, or check productName in package.json" >&2
  exit 1
fi
mkdir -p "$DEST"

base="$APP $(date +%F)"
suffix=""
for s in "" -a -b -c -d -e -f -g -h; do
  if [ ! -e "$DEST/$base$s.zip" ]; then suffix="$s"; break; fi
done
out="$DEST/$base$suffix.zip"
if [ -e "$out" ]; then
  echo "more than nine releases today; tidy $DEST first" >&2
  exit 1
fi

echo "==> packing $BUNDLE"
ditto -c -k --keepParent "$BUNDLE" "$out"

echo
echo "Done."
echo "  $(cd "$(dirname "$out")" && pwd)/$(basename "$out")"
ls -lh "$out" | awk '{print "  " $5}'
