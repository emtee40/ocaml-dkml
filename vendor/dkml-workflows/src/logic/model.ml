(* Useful `dune utop` expressions:


   Workflow_logic.Model.vars_as_object ~allow_dkml_host_abi:(fun _s -> true) ~rewrite_name_value:Workflow_logic.Model.gl_rewrite_name_value ;;

   Workflow_logic.Model.full_matrix_as_list ~allow_dkml_host_abi:(fun _s -> true) ~rewrite_name_value:Workflow_logic.Model.gl_rewrite_name_value ;;
*)
open Astring
open Jingoo

let global_env_vars =
  [
    (* Edited by bump-version.cmake *)
    ("DKML_VERSION", "2.1.1");
    ("DEFAULT_DISKUV_OPAM_REPOSITORY_TAG", "2.1.1");
    ("DEFAULT_OCAML_OPAM_REPOSITORY_TAG", "6c3f73f42890cc19f81eb1dec8023c2cd7b8b5cd");
    ("DEFAULT_DKML_COMPILER", "2.1.1");
    ("BOOTSTRAP_OPAM_VERSION", "v2.2.0-alpha-20221228");

    (* BEGIN pin-env-vars. DO NOT EDIT THE LINES IN THIS SECTION *)
    (* Managed by bump-packages.cmake *)
    ("PIN_ASTRING", "0.8.5");
    ("PIN_BASE", "v0.16.1");
    ("PIN_BASE64", "3.5.1");
    ("PIN_BIGARRAY_COMPAT", "1.1.0");
    ("PIN_BOS", "0.2.1");
    ("PIN_CAMLP_STREAMS", "5.0.1");
    ("PIN_CHROME_TRACE", "3.15.0");
    ("PIN_CMDLINER", "1.2.0");
    ("PIN_CONF_BASH", "1");
    ("PIN_CONF_DKML_SYS_OPAM", "1");
    ("PIN_CONF_PKG_CONFIG", "2+cpkgs");
    ("PIN_CONF_SQLITE3", "3.1+cpkgs");
    ("PIN_CPPO", "1.6.9");
    ("PIN_CRUNCH", "3.3.1");
    ("PIN_CSEXP", "1.5.2");
    ("PIN_CSTRUCT", "6.2.0");
    ("PIN_CTYPES_FOREIGN", "0.19.2-windowssupport-r8");
    ("PIN_CTYPES", "0.19.2-windowssupport-r8");
    ("PIN_CUDF", "0.10");
    ("PIN_DIGESTIF", "1.2.0");
    ("PIN_DISKUVBOX", "0.2.0");
    ("PIN_DKML_APPS", "2.1.1");
    ("PIN_DKML_BASE_COMPILER", "4.14.2~v2.1.1");
    ("PIN_DKML_BUILD_DESKTOP", "2.1.1");
    ("PIN_DKML_C_PROBE", "3.0.0");
    ("PIN_DKML_COMPILER_SRC", "2.1.1");
    ("PIN_DKML_COMPONENT_COMMON_DESKTOP", "2.1.1");
    ("PIN_DKML_COMPONENT_COMMON_OPAM", "2.2.0~alpha0~20221228-r3");
    ("PIN_DKML_COMPONENT_COMMON_UNIXUTILS", "0.2.0");
    ("PIN_DKML_COMPONENT_OCAMLCOMPILER_COMMON", "4.14.2~v2.1.1");
    ("PIN_DKML_COMPONENT_OCAMLCOMPILER_NETWORK", "4.14.2~v2.1.1");
    ("PIN_DKML_COMPONENT_OCAMLCOMPILER_OFFLINE", "4.14.2~v2.1.1");
    ("PIN_DKML_COMPONENT_OFFLINE_DESKTOP_FULL", "2.1.1");
    ("PIN_DKML_COMPONENT_OFFLINE_OPAMSHIM", "2.2.0~alpha0~20221228-r3");
    ("PIN_DKML_COMPONENT_OFFLINE_UNIXUTILS", "0.2.0");
    ("PIN_DKML_COMPONENT_STAGING_DESKTOP_FULL", "2.1.1");
    ("PIN_DKML_COMPONENT_STAGING_DKMLCONFDIR", "2.1.1");
    ("PIN_DKML_COMPONENT_STAGING_OCAMLRUN", "4.14.2~v2.1.1");
    ("PIN_DKML_COMPONENT_STAGING_OPAM32", "2.2.0~alpha0~20221228-r3");
    ("PIN_DKML_COMPONENT_STAGING_OPAM64", "2.2.0~alpha0~20221228-r3");
    ("PIN_DKML_COMPONENT_STAGING_UNIXUTILS", "0.2.0");
    ("PIN_DKML_COMPONENT_STAGING_WITHDKML", "2.1.1");
    ("PIN_DKML_COMPONENT_XX_CONSOLE", "0.1.1");
    ("PIN_DKML_EXE_LIB", "2.1.1");
    ("PIN_DKML_EXE", "2.1.1");
    ("PIN_DKML_INSTALL_INSTALLER", "0.5.2");
    ("PIN_DKML_INSTALL_RUNNER", "0.5.2");
    ("PIN_DKML_INSTALL", "0.5.2");
    ("PIN_DKML_INSTALLER_OCAML_COMMON", "2.1.1");
    ("PIN_DKML_INSTALLER_OCAML_NETWORK", "2.1.1");
    ("PIN_DKML_INSTALLER_OCAML_OFFLINE", "2.1.1");
    ("PIN_DKML_PACKAGE_CONSOLE", "0.5.2");
    ("PIN_DKML_RUNTIME_COMMON_NATIVE", "2.1.1");
    ("PIN_DKML_RUNTIME_COMMON", "2.1.1");
    ("PIN_DKML_RUNTIME_DISTRIBUTION", "2.1.1");
    ("PIN_DKML_RUNTIMELIB", "2.1.1");
    ("PIN_DKML_RUNTIMESCRIPTS", "2.1.1");
    ("PIN_DKML_WORKFLOWS", "2.1.1");
    ("PIN_DUNE_ACTION_PLUGIN", "3.15.0");
    ("PIN_DUNE_BUILD_INFO", "3.15.0");
    ("PIN_DUNE_CONFIGURATOR", "3.15.0");
    ("PIN_DUNE_GLOB", "3.15.0");
    ("PIN_DUNE_PRIVATE_LIBS", "3.15.0");
    ("PIN_DUNE_RPC_LWT", "3.15.0");
    ("PIN_DUNE_RPC", "3.15.0");
    ("PIN_DUNE_SITE", "3.15.0");
    ("PIN_DUNE", "3.15.0");
    ("PIN_DYN", "3.15.0");
    ("PIN_EITHER", "1.0.0");
    ("PIN_EQAF", "0.9");
    ("PIN_EXTLIB", "1.7.9");
    ("PIN_EZJSONM", "1.3.0");
    ("PIN_FEATHER", "0.3.0");
    ("PIN_FIBER", "3.7.0");
    ("PIN_FIX", "20230505");
    ("PIN_FMT", "0.9.0");
    ("PIN_FPATH", "0.7.3");
    ("PIN_GRAPHICS", "5.1.2");
    ("PIN_HEX", "1.5.0");
    ("PIN_HMAP", "0.8.1");
    ("PIN_INTEGERS", "0.7.0");
    ("PIN_IOSTREAM", "0.2.2");
    ("PIN_JANE_STREET_HEADERS", "v0.16.0");
    ("PIN_JINGOO", "1.5.0");
    ("PIN_JSONM", "1.0.2");
    ("PIN_JSONRPC", "1.17.0");
    ("PIN_JST_CONFIG", "v0.16.0");
    ("PIN_LAMBDA_TERM", "3.3.2");
    ("PIN_LOGS", "0.7.0");
    ("PIN_LSP", "1.17.0");
    ("PIN_LWT", "5.7.0");
    ("PIN_LWT_REACT", "1.2.0");
    ("PIN_MCCS", "1.1+13");
    ("PIN_MDX", "2.4.1");
    ("PIN_MENHIR", "20231231");
    ("PIN_MENHIRCST", "20231231");
    ("PIN_MENHIRLIB", "20231231");
    ("PIN_MENHIRSDK", "20231231");
    ("PIN_MERLIN_LIB", "4.14-414");
    ("PIN_METAPP", "0.4.4+win");
    ("PIN_METAQUOT", "0.5.2");
    ("PIN_MEW", "0.1.0");
    ("PIN_MEW_VI", "0.5.0");
    ("PIN_NUM", "1.5");
    ("PIN_OCAML_COMPILER_LIBS", "v0.12.4");
    ("PIN_OCAML_LSP_SERVER", "1.17.0");
    ("PIN_OCAML_VERSION", "3.6.5");
    ("PIN_OCAML", "4.14.2");
    ("PIN_OCAMLBUILD", "0.14.2+win+unix");
    ("PIN_OCAMLC_LOC", "3.15.0");
    ("PIN_OCAMLFIND", "1.9.5");
    ("PIN_OCAMLFORMAT_LIB", "0.26.1");
    ("PIN_OCAMLFORMAT_RPC_LIB", "0.26.1");
    ("PIN_OCAMLFORMAT", "0.26.1");
    ("PIN_OCP_INDENT", "1.8.2-windowssupport");
    ("PIN_OCPLIB_ENDIAN", "1.2");
    ("PIN_ODOC_PARSER", "2.4.1");
    ("PIN_ODOC", "2.4.1");
    ("PIN_ORDERING", "3.15.0");
    ("PIN_PARSEXP", "v0.16.0");
    ("PIN_POSIXAT", "v0.16.0");
    ("PIN_PP", "1.2.0");
    ("PIN_PPX_ASSERT", "v0.16.0");
    ("PIN_PPX_BASE", "v0.16.0");
    ("PIN_PPX_COLD", "v0.16.0");
    ("PIN_PPX_COMPARE", "v0.16.0");
    ("PIN_PPX_DERIVERS", "1.2.1");
    ("PIN_PPX_DERIVING", "5.2.1");
    ("PIN_PPX_ENUMERATE", "v0.16.0");
    ("PIN_PPX_EXPECT", "v0.16.0");
    ("PIN_PPX_GLOBALIZE", "v0.16.0");
    ("PIN_PPX_HASH", "v0.16.0");
    ("PIN_PPX_HERE", "v0.16.0");
    ("PIN_PPX_IGNORE_INSTRUMENTATION", "v0.16.0");
    ("PIN_PPX_INLINE_TEST", "v0.16.1");
    ("PIN_PPX_OPTCOMP", "v0.16.0");
    ("PIN_PPX_PIPEBANG", "v0.16.0");
    ("PIN_PPX_SEXP_CONV", "v0.16.0");
    ("PIN_PPX_YOJSON_CONV_LIB", "v0.16.0");
    ("PIN_PPXLIB", "0.30.0");
    ("PIN_PTIME", "1.1.0");
    ("PIN_QRC", "0.1.1~dune");
    ("PIN_RE", "1.11.0");
    ("PIN_REACT", "1.2.2");
    ("PIN_REFL", "0.4.1");
    ("PIN_RESULT", "1.5");
    ("PIN_RRESULT", "0.7.0");
    ("PIN_SEQ", "base");
    ("PIN_SEXPLIB", "v0.16.0");
    ("PIN_SEXPLIB0", "v0.16.0");
    ("PIN_SHA", "1.15.4");
    ("PIN_SHEXP", "v0.16.0");
    ("PIN_SPAWN", "v0.15.1");
    ("PIN_SQLITE3", "5.1.0+msvc");
    ("PIN_STDCOMPAT", "19+optautoconf");
    ("PIN_STDIO", "v0.16.0");
    ("PIN_STDLIB_SHIMS", "0.3.0");
    ("PIN_STDUNE", "3.15.0");
    ("PIN_TIME_NOW", "v0.16.0");
    ("PIN_TINY_HTTPD", "0.16");
    ("PIN_TOPKG", "1.0.7");
    ("PIN_TRAVERSE", "0.3.0");
    ("PIN_TRIE", "1.0.0");
    ("PIN_TSORT", "2.1.0");
    ("PIN_TYXML", "4.6.0");
    ("PIN_UCHAR", "0.0.2");
    ("PIN_UTOP", "2.13.1");
    ("PIN_UUCP", "15.0.0");
    ("PIN_UUIDM", "0.9.8");
    ("PIN_UUSEG", "15.0.0");
    ("PIN_UUTF", "1.0.3");
    ("PIN_WITH_DKML", "2.1.1");
    ("PIN_XDG", "3.15.0");
    ("PIN_YOJSON", "2.1.2");
    ("PIN_ZED", "3.2.3");
    (* END pin-env-vars. DO NOT EDIT THE LINES ABOVE *)
  ] [@@ocamlformat "disable"]

let required_msys2_packages =
  (*
   Install utilities
   wget: Needed for the Windows Opam download-command
   make: Needed for OCaml ./configure + make
   pkg-config: conf-pkg-config is used by many OCaml packages like digestif.
   rsync: On Windows the `cp` fallback can fail; loosely related to
        https://github.com/ocaml/opam/issues/4080
   diffutils: Needed for diff, which is needed for Opam
   patch: Needed for Opam
   unzip: Needed for Opam
   git: Needed for Opam
   tar: For Opam 2.0 from fdopen, we need MSYS2/Cygwin tar that can handle
      Unix paths like /tmp.
   xz is not for OCaml; just to get opam64.tar.xz from fdopen *)
  Jg_types.Tlist
    (List.map
       (fun s -> Jg_types.Tstr s)
       [
         "wget";
         "make";
         "rsync";
         "diffutils";
         "patch";
         "unzip";
         "git";
         "tar";
         "xz";
       ])

let matrix =
  [
    (*
       ------------
       windows-2019
         https://github.com/actions/virtual-environments/blob/main/images/win/Windows2019-Readme.md
       ------------

       Windows needs to have a short OPAMROOT to minimize risk of exceeding 260 character
       limit.

       But GitLab CI can't cache anything unless it is in the project directory, so GitLab CI
       may encounter 260-character limit problems.

      So the optional `opam_root_cacheable` (which defaults to `opam_root`) is different for
      GitLab (gl) on Windows than `opam_root` so that the former can be in the project directory
      while the latter is a short path that avoids 260 char limit.
    *)
    [
      ("abi_pattern", Jg_types.Tstr {|win32-windows_x86|});
      ("gh_os", Jg_types.Tstr {|windows-2019|} (* 2019 has Visual Studio 2019 *));
      ("gh_unix_shell", Jg_types.Tstr {|msys2 {0}|});
      ("msys2_system", Jg_types.Tstr {|MINGW32|});
      ("msys2_packages", Jg_types.Tstr {|mingw-w64-i686-pkg-config|});
      ("exe_ext", Jg_types.Tstr {|.exe|});
      ("opam_abi", Jg_types.Tstr {|windows_x86|});
      ("dkml_host_abi", Jg_types.Tstr {|windows_x86|});
      ("gh_opam_root", Jg_types.Tstr {|D:/.opam|});
      ("gl_opam_root", Jg_types.Tstr {|C:/o|});
      ("gl_opam_root_cacheable", Jg_types.Tstr {|${CI_PROJECT_DIR}/.ci/o|});
      ("pc_opam_root", Jg_types.Tstr {|${env:PC_PROJECT_DIR}/.ci/o|});
      ("vsstudio_hostarch", Jg_types.Tstr {|x64|});
      ("vsstudio_arch", Jg_types.Tstr {|x86|});
      ("ocaml_options", Jg_types.Tstr {|ocaml-option-32bit|});
    ];
    [
      ("abi_pattern", Jg_types.Tstr {|win32-windows_x86_64|});
      ("gh_os", Jg_types.Tstr {|windows-2019|} (* 2019 has Visual Studio 2019 *));
      ("gh_unix_shell", Jg_types.Tstr {|msys2 {0}|});
      ("msys2_system", Jg_types.Tstr {|CLANG64|});
      ("msys2_packages", Jg_types.Tstr {|mingw-w64-clang-x86_64-pkg-config|});
      ("exe_ext", Jg_types.Tstr {|.exe|});
      ("opam_abi", Jg_types.Tstr {|windows_x86_64|});
      ("dkml_host_abi", Jg_types.Tstr {|windows_x86_64|});
      ("gh_opam_root", Jg_types.Tstr {|D:/.opam|});
      ("gl_opam_root", Jg_types.Tstr {|C:/o|});
      ("gl_opam_root_cacheable", Jg_types.Tstr {|${CI_PROJECT_DIR}/.ci/o|});
      ("pc_opam_root", Jg_types.Tstr {|${env:PC_PROJECT_DIR}/.ci/o|});
      ("vsstudio_hostarch", Jg_types.Tstr {|x64|});
      ("vsstudio_arch", Jg_types.Tstr {|x64|});
    ]
    (* Unnecessary to use VS 14.16, but it serves as a good template for
       other (future) VS versions.
       ;[("gh_os", Jg_types.Tstr "windows-2019"   (* 2019 has Visual Studio 2019 *))
         ; ("abi_pattern", Jg_types.Tstr {|win32_1416-windows_64|} (* VS2017 compiler available to VS2019 *))
         ...
         ; ("vsstudio_hostarch", Jg_types.Tstr {|x64|})
         ; ("vsstudio_arch", Jg_types.Tstr {|x64|})
         ; ("vsstudio_dir", Jg_types.Tstr {|'C:\Program Files (x86)\Microsoft Visual Studio\2019\Enterprise'|})
         ; ("vsstudio_vcvarsver", Jg_types.Tstr {|'14.16'|})
         ; ("vsstudio_winsdkver", Jg_types.Tstr {|'10.0.18362.0'|})
         ; ("vsstudio_msvspreference", Jg_types.Tstr {|'VS16.5'|})
         ; ("vsstudio_cmakegenerator", Jg_types.Tstr {|'Visual Studio 16 2019'|})
         ]
    *)

    (*
        ------------
        windows-2022
          https://github.com/actions/virtual-environments/blob/main/images/win/Windows2022-Readme.md
        ------------

        Disabled because haven't done opam log dumps on failure for
        `opam upgrade`. See https://github.com/diskuv/dkml-component-ocamlcompiler/runs/6059642542?check_suite_focus=true
        ;[("gh_os", Jg_types.Tstr "windows-2022")
          ; ("abi_pattern", Jg_types.Tstr {|win32_2022-windows_x86_64|})
          ...
          ; ("vsstudio_hostarch", Jg_types.Tstr {|x64|})
          ; ("vsstudio_arch", Jg_types.Tstr {|x64|})
          ; ("vsstudio_dir", Jg_types.Tstr {|'C:\Program Files\Microsoft Visual Studio\2022\Enterprise'|})
          ; ("vsstudio_vcvarsver", Jg_types.Tstr {|'14.29'|})
          ; ("vsstudio_winsdkver", Jg_types.Tstr {|'10.0.20348.0'|})
          ; ("vsstudio_msvspreference", Jg_types.Tstr {|'VS16.11'|})
          ; ("vsstudio_cmakegenerator", Jg_types.Tstr {|'Visual Studio 17 2022'|})
          ]
        *);
    [
      ("abi_pattern", Jg_types.Tstr {|macos-darwin_all-intel|});
      (* [no_gl] since no macOS x86_64 machines in GitLab SaaS *)
      ("no_gl", Jg_types.Tstr "true");
      ("gh_os", Jg_types.Tstr "macos-latest");
      (* macos-13-xlarge is Apple Silicon. BUT NOT FREE: https://github.blog/2023-10-02-introducing-the-new-apple-silicon-powered-m1-macos-larger-runner-for-github-actions/ *)
      ("gh_unix_shell", Jg_types.Tstr {|sh|});
      ("dkml_host_abi", Jg_types.Tstr {|darwin_x86_64|});
      ("gh_opam_root", Jg_types.Tstr {|/Users/runner/.opam|});
      ("pc_opam_root", Jg_types.Tstr {|${PC_PROJECT_DIR}/.ci/o|});
    ];
    [
      ("abi_pattern", Jg_types.Tstr {|macos-darwin_all-silicon|});
      (* [no_gh] since no _free_ macOS ARM64 machines in GitHub Actions *)
      ("no_gh", Jg_types.Tstr "true");
      ("gl_image", Jg_types.Tstr "macos-13-xcode-14");
      ("gh_unix_shell", Jg_types.Tstr {|sh|});
      ("dkml_host_abi", Jg_types.Tstr {|darwin_arm64|});
      ("gl_opam_root", Jg_types.Tstr {|${CI_PROJECT_DIR}/.ci/o|});
      ("pc_opam_root", Jg_types.Tstr {|${PC_PROJECT_DIR}/.ci/o|});
    ]
    (* --- NOT APPLICABLE: BUG FIXED ---
       OCaml 4.12.1 can't compile on manylinux2014 x86 (32-bit). It gives:

           /opt/rh/devtoolset-10/root/usr/bin/gcc -c -O2 -fno-strict-aliasing -fwrapv -Wall -Wdeclaration-after-statement -fno-common -fexcess-precision=standard -fno-tree-vrp -ffunction-sections -g -Wno-format -D_FILE_OFFSET_BITS=64 -D_REENTRANT -DCAML_NAME_SPACE   -DCAMLDLLIMPORT= -DNATIVE_CODE -DTARGET_amd64 -DMODEL_default -DSYS_linux   -o signals_nat.n.o signals_nat.c
           In file included from signals_nat.c:35:
           signals_nat.c: In function ‘segv_handler’:
           signals_osdep.h:34:72: error: ‘REG_CR2’ undeclared (first use in this function); did you mean ‘REG_CS’?
             34 | define CONTEXT_FAULTING_ADDRESS ((char * )context->uc_mcontext.gregs[REG_CR2])
                 |                                                                        ^~~~~~~
           signals_nat.c:207:16: note: in expansion of macro ‘CONTEXT_FAULTING_ADDRESS’
             207 |   fault_addr = CONTEXT_FAULTING_ADDRESS;
                 |                ^~~~~~~~~~~~~~~~~~~~~~~~
           signals_osdep.h:34:72: note: each undeclared identifier is reported only once for each function it appears in
             34 | define CONTEXT_FAULTING_ADDRESS ((char * )context->uc_mcontext.gregs[REG_CR2])
                 |                                                                        ^~~~~~~
           signals_nat.c:207:16: note: in expansion of macro ‘CONTEXT_FAULTING_ADDRESS’
             207 |   fault_addr = CONTEXT_FAULTING_ADDRESS;
                 |                ^~~~~~~~~~~~~~~~~~~~~~~~
           signals_osdep.h:32:50: error: ‘REG_RSP’ undeclared (first use in this function); did you mean ‘REG_ESP’?
             32 | define CONTEXT_SP (context->uc_mcontext.gregs[REG_RSP])
                 |                                                  ^~~~~~~
           signals_nat.c:210:33: note: in expansion of macro ‘CONTEXT_SP’
             210 |       && (uintnat)fault_addr >= CONTEXT_SP - EXTRA_STACK
                 |                                 ^~~~~~~~~~
           signals_osdep.h:31:50: error: ‘REG_RIP’ undeclared (first use in this function); did you mean ‘REG_EIP’?
             31 | define CONTEXT_PC (context->uc_mcontext.gregs[REG_RIP])
                 |                                                  ^~~~~~~
           signals_nat.c:212:49: note: in expansion of macro ‘CONTEXT_PC’
             212 |       && caml_find_code_fragment_by_pc((char * ) CONTEXT_PC) != NULL
                 |                                                 ^~~~~~~~~~
           make[1]: *** [signals_nat.n.o] Error 1
           make[1]: Leaving directory `/work/opamroot/dkml/src-ocaml/runtime'
           make: *** [makeruntimeopt] Error 2
           FATAL: make opt-core failed *);
    (*
       Linux
       -----

       OPAMROOT needs to be a local directory of the checked-out code because dockcross only
       mounts that directory as /work.
    *)
    [
      ("abi_pattern", Jg_types.Tstr {|manylinux2014-linux_x86|});
      ("gh_os", Jg_types.Tstr "ubuntu-latest");
      ("gh_unix_shell", Jg_types.Tstr {|sh|});
      ("dkml_host_abi", Jg_types.Tstr {|linux_x86|});
      ("gh_opam_root", Jg_types.Tstr {|.ci/o|});
      ("gl_opam_root", Jg_types.Tstr {|.ci/o|});
      ("pc_opam_root", Jg_types.Tstr {|.ci/o|});
      ("in_docker", Jg_types.Tstr {|true|});
      ("dockcross_image", Jg_types.Tstr {|dockcross/manylinux2014-x86|});
      (* Gets rid of: WARNING: The requested image's platform (linux/386) does not match the detected host platform (linux/amd64) and no specific platform was requested *)
      ("dockcross_run_extra_args", Jg_types.Tstr {|--platform linux/386|});
    ]
    (* ("gh_os", ubuntu-latest
        ; ("abi_pattern", Jg_types.Tstr {|manylinux_2_24-linux_x86|})
        ; ("gh_unix_shell", Jg_types.Tstr {|sh|})
        ; ("dkml_host_abi", Jg_types.Tstr {|linux_x86|})
        ; ("gh_opam_root", Jg_types.Tstr {|.ci/o|})
        ; ("gl_opam_root", Jg_types.Tstr {|.ci/o|})
        ; ("pc_opam_root", Jg_types.Tstr {|.ci/o|})
        ; ("docker_runner", Jg_types.Tstr {|docker run --platform linux/386 --rm -v $GITHUB_WORKSPACE:/work --workdir=/work quay.io/pypa/manylinux_2_24_i686 linux32|})
        ; ("in_docker", Jg_types.Tstr {|true|})
          ] *);
    [
      ("abi_pattern", Jg_types.Tstr {|manylinux2014-linux_x86_64|});
      ("gh_os", Jg_types.Tstr "ubuntu-latest");
      ("gh_unix_shell", Jg_types.Tstr {|sh|});
      ("dkml_host_abi", Jg_types.Tstr {|linux_x86_64|});
      ("gh_opam_root", Jg_types.Tstr {|.ci/o|});
      ("gl_opam_root", Jg_types.Tstr {|.ci/o|});
      ("pc_opam_root", Jg_types.Tstr {|.ci/o|});
      ("dockcross_image", Jg_types.Tstr {|dockcross/manylinux2014-x64|});
      (* Use explicit platform because setup-dkml.sh will bypass 'dockcross' script (which hardcodes the --platform)
         when the invoking user is root. In that situation the following arguments are used. *)
      ("dockcross_run_extra_args", Jg_types.Tstr {|--platform linux/amd64|});
      ("in_docker", Jg_types.Tstr {|true|});
    ];
  ]

module Aggregate = struct
  type t = {
    mutable dkml_host_os_opt : Jg_types.tvalue option;
    mutable dkml_host_abi_opt : string option;
    mutable opam_root_opt : string option;
    mutable opam_root_cacheable_opt : string option;
    mutable supports_gh : bool;
    mutable supports_gl : bool;
  }

  let create () =
    {
      dkml_host_os_opt = None;
      dkml_host_abi_opt = None;
      opam_root_opt = None;
      opam_root_cacheable_opt = None;
      supports_gh = true;
      supports_gl = true;
    }

  let capture ~name ~value t =
    let value_if_string value =
      if Jg_types.type_string_of_tvalue value = "string" then
        Some (Jg_types.unbox_string value)
      else None
    in
    let value_as_string = value_if_string value in
    (* Capture scalar values *)
    (match name with
    | "dkml_host_abi" -> t.dkml_host_abi_opt <- value_as_string
    | "opam_root" -> t.opam_root_opt <- value_as_string
    | "opam_root_cacheable" -> t.opam_root_cacheable_opt <- value_as_string
    | "no_gh" -> t.supports_gh <- false
    | "no_gl" -> t.supports_gl <- false
    | _ -> ());
    (* Capture dkml_host_os *)
    match (name, Option.map (String.cuts ~sep:"_") value_as_string) with
    | "dkml_host_abi", Some (value_head :: _value_tail) ->
        t.dkml_host_os_opt <- Some (Jg_types.Tstr value_head)
    | _ -> ()

  let dkml_host_abi_opt t = t.dkml_host_abi_opt
  let opam_root_opt t = t.opam_root_opt
  let opam_root_cacheable_opt t = t.opam_root_cacheable_opt
  let supports_gl t = t.supports_gl
  let supports_gh t = t.supports_gh

  let dump t =
    match
      ( t.dkml_host_os_opt,
        t.dkml_host_abi_opt,
        t.opam_root_opt,
        t.opam_root_cacheable_opt )
    with
    | ( Some dkml_host_os,
        Some dkml_host_abi,
        Some opam_root,
        opam_root_cacheable_opt ) ->
        let opam_root_cacheable =
          Option.fold ~none:opam_root
            ~some:(fun opam_root_cacheable -> opam_root_cacheable)
            opam_root_cacheable_opt
        in
        [
          ("dkml_host_abi", Jg_types.Tstr dkml_host_abi);
          ("dkml_host_os", dkml_host_os);
          ("opam_root", Jg_types.Tstr opam_root);
          ("opam_root_cacheable", Jg_types.Tstr opam_root_cacheable);
        ]
    | Some _, None, Some _, _ ->
        failwith "Expected dkml_host_abi would be found"
    | Some _, Some _, None, _ -> failwith "Expected opam_root would be found"
    | None, Some _, Some _, _ ->
        failwith "Expected dkml_host_os would be derived"
    | _ ->
        failwith
          "Expected dkml_host_abi and opam_root would be found and \
           dkml_host_os would be derived"
end

(**

  The field [opam_root_cacheable] will default to [opam_root] unless explicitly
  set.

  {v
    { vars: [
        { name: "abi_pattern", value: 'win32-windows_x86' },
        { name: "gh_unix_shell", value: 'msys2 {0}' },
        { name: "msys2_system", value: 'MINGW32' },
        { name: "msys2_packages", value: 'mingw-w64-i686-pkg-config' },
        { name: "exe_ext", value: '.exe' },
        { name: "opam_abi", value: 'windows_x86' },
        { name: "dkml_host_abi", value: 'windows_x86' },
        { name: "opam_root", value: '${CI_PROJECT_DIR}/.ci/o' },
        { name: "vsstudio_hostarch", value: 'x64' },
        { name: "vsstudio_arch", value: 'x86' },
        { name: "ocaml_options", value: 'ocaml-option-32bit' },
        ...
      ],
      dkml_host_abi: "windows_x86",
      dkml_host_os: "windows",
      opam_root: "${CI_PROJECT_DIR}/.ci/o",
      opam_root_cacheable: "${CI_PROJECT_DIR}/.ci/o",
  v}
*)
let full_matrix_as_list ?must_support_gl ?must_support_gh ~allow_dkml_host_abi
    ~rewrite_name_value () =
  List.filter_map
    (fun matrix_item ->
      let aggregate = Aggregate.create () in
      let vars =
        Jg_types.Tlist
          (List.filter_map
             (fun (name, value) ->
               (* make name value pair unless ~rewrite_name_value is None *)
               match rewrite_name_value ~name ~value () with
               | None ->
                   (* capture aggregates *)
                   Aggregate.capture ~name ~value aggregate;
                   None
               | Some (name', value') ->
                   (* capture aggregates (after rewriting!) *)
                   Aggregate.capture ~name:name' ~value:value' aggregate;
                   Some
                     (Jg_types.Tobj
                        [ ("name", Jg_types.Tstr name'); ("value", value') ]))
             matrix_item)
      in
      match Aggregate.dkml_host_abi_opt aggregate with
      | Some dkml_host_abi -> (
          match
            ( must_support_gh,
              Aggregate.supports_gh aggregate,
              must_support_gl,
              Aggregate.supports_gl aggregate )
          with
          | Some (), false, _, _ -> None
          | _, _, Some (), false -> None
          | _ ->
              if allow_dkml_host_abi dkml_host_abi then
                Some
                  (Jg_types.Tobj ([ ("vars", vars) ] @ Aggregate.dump aggregate))
              else None)
      | None -> None)
    matrix

(**

  {v
    windows_x86: {
      abi_pattern: 'win32-windows_x86',
      gh_unix_shell: 'msys2 {0}',
      msys2_system: 'MINGW32',
      msys2_packages: 'mingw-w64-i686-pkg-config',
      exe_ext: '.exe',
      opam_abi: 'windows_x86',
      dkml_host_abi: 'windows_x86',
      opam_root: '${CI_PROJECT_DIR}/.ci/o',
      vsstudio_hostarch: 'x64',
      vsstudio_arch: 'x86',
      ocaml_options: 'ocaml-option-32bit' }
  v}
*)
let vars_as_object ?must_support_gl ?must_support_gh ~allow_dkml_host_abi
    ~rewrite_name_value () =
  let matrix =
    full_matrix_as_list ?must_support_gl ?must_support_gh ~allow_dkml_host_abi
      ~rewrite_name_value ()
  in
  let filter_vars f (vars : Jg_types.tvalue list) : Jg_types.tvalue list =
    List.filter
      (function
        | Jg_types.Tobj
            [ ("name", Jg_types.Tstr name); ("value", Jg_types.Tstr value) ] ->
            f ~name ~value
        | _ -> false)
      vars
  in
  let vars =
    List.map
      (function
        | Jg_types.Tobj
            [
              ("vars", Jg_types.Tlist vars);
              ("dkml_host_abi", Jg_types.Tstr dkml_host_abi);
              ("dkml_host_os", Jg_types.Tstr dkml_host_os);
              ("opam_root", Jg_types.Tstr _opam_root);
              ("opam_root_cacheable", Jg_types.Tstr opam_root_cacheable);
            ] ->
            ( dkml_host_abi,
              Jg_types.Tobj
                [
                  ("name", Jg_types.Tstr "dkml_host_os");
                  ("value", Jg_types.Tstr dkml_host_os);
                ]
              :: Jg_types.Tobj
                   [
                     ("name", Jg_types.Tstr "opam_root_cacheable");
                     ("value", Jg_types.Tstr opam_root_cacheable);
                   ]
              :: filter_vars
                   (fun ~name ~value:_ ->
                     not (String.equal name "opam_root_cacheable"))
                   vars )
        | _ ->
            failwith
              "Expecting [('vars', Tlist varlist); ('dkml_host_abi', ...); \
               ('dkml_host_os', ...); ('opam_root', ...); \
               ('opam_root_cacheable', ...); ...] where vars is the first item")
      matrix
  in
  let f_vars_to_obj = function
    | Jg_types.Tobj [ ("name", Jg_types.Tstr name'); ("value", value') ] ->
        (name', value')
    | v ->
        let msg =
          Format.asprintf
            "Expecting vars is a list of [('name', varlist); ('value', \
             value)]. Instead a list item was:@ %a"
            Jg_types.pp_tvalue v
        in
        prerr_endline ("FATAL: " ^ msg);
        failwith msg
  in
  Jg_types.Tobj
    (List.map
       (fun (dkml_host_abi, vars) ->
         (dkml_host_abi, Jg_types.Tobj (List.map f_vars_to_obj vars)))
       vars)

let gh_rewrite_name_value ~name ~value () =
  match
    ( name,
      String.is_prefix ~affix:"gl" name || String.is_prefix ~affix:"pc" name )
  with
  | _, true -> None
  | "gh_opam_root", _ -> Some ("opam_root", value)
  | "gh_opam_root_cacheable", _ -> Some ("opam_root_cacheable", value)
  | _ -> Some (name, value)

let gl_rewrite_name_value ~name ~value () =
  match
    ( name,
      String.is_prefix ~affix:"gh" name || String.is_prefix ~affix:"pc" name )
  with
  | _, true -> None
  | "gl_opam_root", _ -> Some ("opam_root", value)
  | "gl_opam_root_cacheable", _ -> Some ("opam_root_cacheable", value)
  | _ -> Some (name, value)

let pc_rewrite_name_value ~name ~value () =
  match
    ( name,
      String.is_prefix ~affix:"gh" name || String.is_prefix ~affix:"gl" name )
  with
  | _, true -> None
  | "pc_opam_root", _ -> Some ("opam_root", value)
  | "pc_opam_root_cacheable", _ -> Some ("opam_root_cacheable", value)
  | _ -> Some (name, value)

let model ~allow_dkml_host_abi ~read_script =
  [
    ( "global_env_vars",
      Jg_types.Tlist
        (List.map
           (fun (name, value) ->
             Jg_types.Tobj
               [ ("name", Jg_types.Tstr name); ("value", Jg_types.Tstr value) ])
           global_env_vars) );
    ( "gh_matrix",
      Jg_types.Tlist
        (full_matrix_as_list ~allow_dkml_host_abi ~must_support_gh:()
           ~rewrite_name_value:gh_rewrite_name_value ()) );
    ( "gh_vars",
      vars_as_object ~allow_dkml_host_abi ~must_support_gh:()
        ~rewrite_name_value:gh_rewrite_name_value () );
    ( "gl_matrix",
      Jg_types.Tlist
        (full_matrix_as_list ~allow_dkml_host_abi ~must_support_gl:()
           ~rewrite_name_value:gl_rewrite_name_value ()) );
    ( "gl_vars",
      vars_as_object ~allow_dkml_host_abi ~must_support_gl:()
        ~rewrite_name_value:gl_rewrite_name_value () );
    ( "pc_matrix",
      Jg_types.Tlist
        (full_matrix_as_list ~allow_dkml_host_abi
           ~rewrite_name_value:pc_rewrite_name_value ()) );
    ( "pc_vars",
      vars_as_object ~allow_dkml_host_abi
        ~rewrite_name_value:pc_rewrite_name_value () );
    ("required_msys2_packages", required_msys2_packages);
  ]
  @ Scripts.to_vars read_script
  @ Typography.vars @ Caching.static_vars
  @ Caching.gh_cachekeys read_script
  @ Caching.gl_cachekeys read_script
