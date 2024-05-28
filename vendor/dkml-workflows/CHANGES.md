# Changes

## 2.1.1

- `bootstrap_opam_version` and `FDOPEN_OPAMEXE_BOOTSTRAP` are no longer part of CI matrix. The bootstrap opam version is now tied to the DkML release and always comes from dkml-component-opam's release assets.
- Docfixes: Using PC backends uses new `.ci/dkml-compilers` folder, and is self-contained with an initial `CI Desktop` step.
- Change GitLab Desktop script temporary directory to `.ci/sd4/tmp` so part of .gitignore created by `./dk dkml.workflow.compilers CI Desktop`.
- Change GitLab macOS tags to `saas-macos-medium-m1` from `shared-macos-amd64`
- Lessen verbosity of logs
- Upgrade GitLab Docker-in-Docker image from 20.10.16 to 25.0.3
- Propagate `CI` environment variable into Docker-in-Docker
- Switch to git-based opam repository. Now `opam update` takes 8.5min rather than 12min on Windows GitHub Actions.
- Upgrade to MSYS2 20240113
- Allow pre-existing MSYS2 in a `MSYS2_BASEDIR` environment variable which must have an `msys64\` subfolder.

## 2.1.0

- Support macOS ARM64
- Bump GitLab SaaS hardware from `macos-11-xcode-12` (x86_64) to `macos-12-xcode-14` (arm64)

## 1.2.1

> The minimum Dune language requirement is `(lang dune 3.0)`. Please update
> your `dune-project`.
  
- Support WinSDK 19041 and Visual Studio 14.29
- For non-Windows PC scripts, allow docker image to be overridden
- Add `.ci/local/bin` to opamrun PATH so user workflow can add its own
  binaries
- Bump opam on 2.2 trunk from `2.2.0-dkml20220801T155940Z` to
  `2.2.0-alpha-20221228`
- New input variable `SKIP_OPAM_MODIFICATIONS` will, when "true", will skip the
  creating or modifying the opam root and the switches.
- Make `cmdrun` script that does not run opam automatically, especially when
  using `SKIP_OPAM_MODIFICATIONS`
- New input variable `PRIMARY_SWITCH_SKIP_INSTALL` will skip the install of
  the dkml-base-compiler but will still set up DKML pins and repositories
- Check if dkml-workflow binaries are present before enabling rules to
  regenerate CI scripts from @gen-dkml target

## 1.2.0 (v1)

- Upgrade OCaml from 4.12.1 to 4.14.0
- Desktop testing for Linux works with plain MSYS2 on Windows (using docker)
- Fix bug on GitLab CI where MSYS2 calling into cmd.exe could leave the
  GitLab CI session as Command Prompt rather than the usual PowerShell.

## 1.1.0 (v1)

New Features:

- Desktop testing for macOS/Intel (or macOS/ARM64 with Rosetta emulator) and Linux 32/64-bit on Intel/AMD
- Help messages for desktop testing on Windows
- Optional secondary switch `two` in addition to primary switch `dkml` enabled with
  input variable `SECONDARY_SWITCH=true`

Breaking changes:

- The GitLab job names `build_linux`, `build_macos` and `build_win32` are now private job names `.linux:setup-dkml`,
  `.macos:setup-dkml` and `.win32:setup-dkml`. This means in your own `.gitlab-ci.yml` you will need an "extends" statement,
  like so:

  ```yaml
  build_linux:
    extends: .linux:setup-dkml # ADD THIS ONE LINE!
    script:
      - opamrun exec -- echo Build me some Linux stuff
  ```

  *Why break the API?*

  This change was done so you could do incremental staged builds where job A does only the setup (which caches the OCaml
  compiler) and where the second job B does both the setup and the full build of your OCaml code. By using a private job
  name that starts with a dot (.) like `.linux:setup-dkml`, both job A and job B can extend from `.**OS**:setup-dkml` to
  share the setting up of the OCaml compiler cache.

  The benefit you get for the extra complexity is that you are more likely to stay under GitLab runner
  time limits; the shared SaaS GitLab runners time out jobs at 2 hours.
  For example Job A can take one hour or more for Windows when you enable `SECONDARY_SWITCH=true`.

  Hypothetically you could do a full build of your code without the caching of the OCaml compiler that took 2.5 hours.
  GitLab would fail your full build with time limit failures. But by splitting job A from job B, job A takes 1-1.5 hours
  while job B would only take 1.5 hours plus a few minutes for reading the cache of job A. Now both job A and job B
  can work without running into time limits.

  *Why is it a minor break?*

  Since there was no announcement of the previous 1.0.0 version, it is unlikely anyone is broken. And if
  anyone is broken, they just need to add three `extends: .setup_dkml_XXX` to their script.

Other changes:

- Performance: Linux CI now avoids ~10 second ManyLinux (dockcross) unnecessary recursive chown of root:root
  owned container files. As long as calling user is root (which is true for GitHub Actions and GitLab CI/CD)
  the chown operation is skipped.
- Remove unused `gl_tags` matrix variable

## 1.0.0 (v1)

New Features:

1. Support GitLab CI/CD
2. Support desktop testing on Windows
3. GitHub now uses a composite action rather than a child
   workflow, resulting in less artifact copying and
   quicker builds.

There are significant breaking changes. It will be far easier
to onboard with [the new version `v1` instructions](https://github.com/diskuv/dkml-workflows/tree/v1#readme)
and then remove your `v0` code, rather than try to do an in-place upgrade:

- Any custom build logic you have in your GitHub workflow should go into
  the new `ci/build-test.sh`. Alternatively, if you don't care about ever running troubleshooting
  CI on your desktop or GitLab, directly into your new `.github/workflows/build-with-dkml.yml`.

Breaking changes:

- The GitHub child workflow has been replaced by a GitHub composite action
- Input variables have been renamed to allow the same variable names between GitHub Actions and
  GitLab CI/CD (the latter does not support dashes in variable names).

  | Old Name                  | New Name                  |
  | ------------------------- | ------------------------- |
  | cache-prefix              | CACHE_PREFIX              |
  | ocaml-compiler            | OCAML_COMPILER            |
  | dkml-compiler             | DKML_COMPILER             |
  | conf-dkml-cross-toolchain | CONF_DKML_CROSS_TOOLCHAIN |
  | diskuv-opam-repository    | DISKUV_OPAM_REPOSITORY    |
  | ocaml-options             | ocaml_options             |
  | vsstudio-arch             | vsstudio_arch             |
  | vsstudio-hostarch         | vsstudio_hostarch         |
  | vsstudio-dir              | vsstudio_dir              |
  | vsstudio-vcvarsver        | vsstudio_vcvarsver        |
  | vsstudio-winsdkver        | vsstudio_winsdkver        |
  | vsstudio-msvspreference   | vsstudio_msvspreference   |
  | vsstudio-cmakegenerator   | vsstudio_cmakegenerator   |

- Matrix variables have been renamed to allow the same variable names between GitHub Actions and
  GitLab CI/CD (the latter does not support dashes in variable names).

- The shell matrix variable `default_shell` has been renamed `gh_unix_shell`

- The operating system matrix variable has been reorganized to distingush GitHub
  from GitLab:

  - `os` is now `gh_os` and in use only for GitHub Actions
  - `gl_tags` and `gl_image` are the new GitLab CI/CD equivalents. GitLab CI/CD uses tags like
    `[shared-windows, windows, windows-1809]` to specify the type of runner machine to use,
    and for macOS image you can supply an XCode version like `macos-11-xcode-12`.

## v0

Initial release
