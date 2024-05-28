#!/bin/sh
set -euf

if ! [ -d "vendor/@SUBTREE_PROJECT@" ]; then
    echo "FATAL: Must be executed from the dkml project directory" >&2
    exit 1
fi

git subtree push --prefix "vendor/@SUBTREE_PROJECT@" "@subtree_URL@" "@subtree_BRANCH@"
