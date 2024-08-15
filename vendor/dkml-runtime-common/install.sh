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
install macos/brewbundle.sh "$targetdir/macos/"
install unix/_common_tool.sh unix/_within_dev.sh unix/crossplatform-functions.sh "$targetdir/unix/"
