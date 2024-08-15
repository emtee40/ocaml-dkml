# desktop 0.1.0

A component providing all the opam package files marked with `global-install`
in the [DKML runtime distribution packages](https://github.com/diskuv/dkml-runtime-distribution/tree/main/src/none).

These package files are executables, man pages and other assets which will be
available in the end-user installation directory.

## Developing

You can test on your desktop with a session as follows:

```console
# For macOS/Intel (darwin_x86_64)
$ sh ci/setup-dkml/pc/setup-dkml-darwin_x86_64.sh --SECONDARY_SWITCH=true -DKML_HOME .ci/dkml-home
# For Linux/Intel (linux_x86_64). You will need Docker
#   - Running this from macOS with Docker will also work
#   - Running this using with-dkml.exe on Windows with Docker will also work
#     (the normal Linux containers host, not the Windows containers host)
$ sh ci/setup-dkml/pc/setup-dkml-linux_x86_64.sh --SECONDARY_SWITCH=true -DKML_HOME .ci/dkml-home
# For Windows (windows_x86_64) in PowerShell
$ & .\ci\setup-dkml\pc\setup-dkml-windows_x86_64.ps1 -SECONDARY_SWITCH true -DKML_HOME .ci/dkml-home
...
Finished setup.

To continue your testing, run:
  export dkml_host_abi='darwin_x86_64'
  export abi_pattern='macos-darwin_all'
  export opam_root='/Volumes/Source/dkml-component-desktop/.ci/o'
  export exe_ext=''

Now you can use 'opamrun' to do opam commands like:

  opamrun install XYZ.opam
  sh ci/build-test.sh

# Copy and adapt from above (the text above will be different for each of: Linux, macOS and Windows)
$ export dkml_host_abi='darwin_x86_64'
$ export abi_pattern='macos-darwin_all'
$ export opam_root="$PWD/.ci/o"
$ export exe_ext=''

# Run the build
#   The first argument is: 'ci' or 'full'
#   The second argument is: 'release' or 'next'
$ sh ci/build-test.sh ci next
```

## Upgrading binary assets

1. Make a `-prep` tag, and then wait for the CI to complete successfully
2. Update `desktop.version.txt`
3. Run: `dune build '@gen-opam' --auto-promote`
4. Run: `dune build *.opam`

## Upgrading CI including OCaml version

Optional: Do the following to get the bleeding edge:

```bash
opam pin remove crunch --no-action --yes
opam pin remove cmdliner --no-action --yes
opam pin dkml-workflows git+https://github.com/diskuv/dkml-workflows-prerelease.git#v1 --no-action --yes
```

```bash
opam upgrade dkml-workflows && opam exec -- generate-setup-dkml-scaffold && dune build '@gen-dkml' --auto-promote
```

## Build Flow

1. See [dkml-runtime-distribution](https://github.com/diskuv/dkml-runtime-distribution/blob/main/src/none/README.md)
   for how the packages that participate in the DKML distribution are specified. The actual specification of the
   packages is in the [same directory](https://github.com/diskuv/dkml-runtime-distribution/blob/main/src/none/)
2. Gitlab CI/CD on macOS, Linux and Windows machines will:
   1. Make a "secondary" switch `two` that contains [dkml-build-desktop.opam](./dkml-build-desktop.opam). That will
      have install the list of `dkml-runtime-distribution` package specifications. The tests for dkml-build-desktop
      will also have checked that the opam pins specified in the GitLab `.gitlab-ci.yml` file, which are used
      in the next step, match the `dkml-runtime-distribution` package specifications.
   2. Make a primary switch `dkml` that installs all the packages specified by `dkml-runtime-distribution`, including
      pinning the packages to their `dkml-runtime-distribution` specified versions.
   3. Go through every specified package and ask Opam for the list of files that were installed by those packages.
   4. Export the Opam installed files as a tarball for consumption by the "release" job.

   Then the release job will import all the Opam installed files and make a single tarball that contains all
   macOS, Linux and Windows binaries.
3. `dkml-component-staging-desktop-{ci,full}.opam` will use the GitLab Release tarball as an `extra-source`.
   When opam builds the `...-{ci,full}.opam` packages, the tarball files will be moved into the `staging-files`
   "share" folder.
4. The DKML installer uses the `dkml-component-offline-desktop-{ci,full}.opam` packages with dkml-install-api to make
   installer executables:
   * The offline components depends on the staging components, so during end-user installation the
     `staging-files` will be present in a temporary directory.
   * The offline components use [src/installtime_enduser/install.ml](src/installtime_enduser/install.ml) to:
     1. Copy the `staging-files` to the end-user installation prefix.
     2. Copy the `staging-files/<abi>/bin/fswatch.exe` to `tools/fswatch/fswatch.exe` if and only if
        the `<abi>` is Windows.

## Status

[![Pipeline Status](https://gitlab.com/dkml/components/dkml-component-desktop/badges/main/pipeline.svg)](https://gitlab.com/dkml/components/dkml-component-desktop/-/blob/main/.gitlab-ci.yml)
