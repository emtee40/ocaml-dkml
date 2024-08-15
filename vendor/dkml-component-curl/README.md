# curl 0.1.0

The `staging-curl` component provides `curl` or `curl.exe` on all
DKML installable platforms, including Windows.

This is a component that can be used with [dkml-install-api](https://diskuv.github.io/dkml-install-api/index.html)
to generate installers.

## Usage

> `%{staging-curl:share-abi}%/bin/curl`

On Windows curl 7.81.0 or later will be available. Use this
`curl` rather than Windows' `C:\Windows\System32\curl.exe` since the latter is
only pre-installed in Windows 10 Build 17063 and later.

On Unix and macOS the `curl` is a symlink to whichever `curl` is found on
the PATH.

## Contributing

See [the Contributors section of dkml-install-api](https://github.com/diskuv/dkml-install-api/blob/main/contributors/README.md).

## Status

[![Syntax check](https://github.com/diskuv/dkml-component-curl/actions/workflows/syntax.yml/badge.svg)](https://github.com/diskuv/dkml-component-curl/actions/workflows/syntax.yml)
