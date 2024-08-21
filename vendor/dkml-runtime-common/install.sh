#!/bin/sh

targetdir=$1
shift

echo -- ---------------------
echo Arguments:
echo "  Target directory = $targetdir"
echo -- ---------------------

install -d "$targetdir/macos" "$targetdir/unix"

install META "$targetdir/"
install template.dkmlroot "$targetdir/"

# Copy scripts. No CRLF allowed.
#
#   shellcheck disable=SC2043
for i in brewbundle.sh; do
    tr -d '\r' macos/$i > "$targetdir/macos/$i"
    chmod +x "$targetdir/macos/$i"
done
for i in _common_tool.sh _within_dev.sh crossplatform-functions.sh; do
    tr -d '\r' unix/$i > "$targetdir/unix/$i"
    chmod +x "$targetdir/unix/$i"
done
