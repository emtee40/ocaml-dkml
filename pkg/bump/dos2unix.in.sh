#!/bin/sh
set -euf

if [ -x /usr/bin/dos2unix ]; then
    /usr/bin/dos2unix "$1"
fi
