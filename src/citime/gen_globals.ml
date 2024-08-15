type distro_type = Dune | Ci | Full
type output_format = Shell_function_calls | Package_versions | Packages

(** Must be safe for single-quoting in a POSIX shell script. And it
    must also be a reasonable, expected Opam package and version (this is whitelist
    sanitization!).

    Valid examples:

    {v
    dune.2.9.3+shim.1.0.1
    ocp-indent.1.8.2-windowssupport
    dkml-runtime-distribution.~dev
    lwt_react.1.2.3
    v}
*)
let re_sanitize =
  Re.compile
    Re.(
      seq
        [
          bos;
          rep (alt [ alnum; digit; char '_'; char '.'; char '~'; char '-'; char '+' ]);
          eos;
        ])

let gen_packages pkgs =
  List.iter (fun (pkg, _ver) -> Printf.printf "%s\n" pkg) pkgs

let gen_package_versions pkgs =
  List.iter (fun (pkg, ver) -> Printf.printf "%s.%s\n" pkg ver) pkgs

(** Generate the POSIX shell function calls *)
let gen_shell_function_calls pkgs ~global_type_name =
  let pkgs_with_spaces =
    String.concat " " (List.map (fun (pkg, _ver) -> pkg) pkgs)
  in
  let pkgvers_with_spaces =
    String.concat " "
      (List.map (fun (pkg, ver) -> Printf.sprintf "%s.%s" pkg ver) pkgs)
  in
  Printf.printf "echo '--- START [## global-%s] PACKAGE VERSIONS ---'\n"
    global_type_name;
  Printf.printf "start_pkg_vers %s\n" pkgvers_with_spaces;
  Printf.printf "echo '--- WITH [## global-%s] PACKAGE VERSIONS ---'\n"
    global_type_name;
  List.iter
    (fun (pkg, ver) -> Printf.printf "with_pkg_ver '%s' '%s'\n" pkg ver)
    pkgs;
  Printf.printf "echo '--- END [## global-%s] PACKAGES ---'\n" global_type_name;
  Printf.printf "end_pkgs %s\n" pkgs_with_spaces;
  Printf.printf "echo '--- POST [## global-%s] PACKAGE VERSIONS ---'\n"
    global_type_name;
  List.iter (fun (pkg, _ver) -> Printf.printf "post_pkg '%s'\n" pkg) pkgs

let () =
  let global_type_name, global_directive =
    match Sys.argv.(1) with
    | "compile" -> ("compile", Dkml_runtime_distribution.Config.Global_compile)
    | "install" -> ("install", Dkml_runtime_distribution.Config.Global_install)
    | v -> failwith ("Unsupported global type: " ^ v)
  in
  let distro_type =
    match Sys.argv.(2) with
    | "dune" -> Dune
    | "ci" -> Ci
    | "full" -> Full
    | v -> failwith ("Unsupported distro type: " ^ v)
  in
  let output_format =
    match Sys.argv.(3) with
    | "shell-function-calls" -> Shell_function_calls
    | "package-versions" -> Package_versions
    | "packages" -> Packages
    | v -> failwith ("Unsupported output format: " ^ v)
  in
  (* Decide which packages are to be built *)
  let pkgs =
    let open Dkml_runtime_distribution in
    (* Which distribution? Ci or Ci+Full? *)
    let pkgs =
      match distro_type with
      | Dune -> Config.dune_pkgs
      | Ci -> Config.ci_pkgs
      | Full -> Config.ci_pkgs @ Config.full_pkgs
    in
    (* Only [## global-install] directives *)
    List.filter_map
      (fun (pkgname, pkgver, directives) ->
        match List.mem global_directive directives with
        | true -> Some (pkgname, pkgver)
        | false -> None)
      pkgs
  in
  (* Sanitize inputs. Do not trust the packages! *)
  List.iter
    (fun (pkg, ver) ->
      if not (Re.execp re_sanitize pkg) then
        failwith
          (Printf.sprintf
             "The package name '%s' is not safe for a POSIX shell script" pkg);
      if not (Re.execp re_sanitize ver) then
        failwith
          (Printf.sprintf
             "The version '%s' of package '%s' is not safe for a POSIX shell \
              script"
             ver pkg))
    pkgs;
  (* Generate the POSIX shell function calls *)
  match output_format with
  | Shell_function_calls -> gen_shell_function_calls pkgs ~global_type_name
  | Package_versions -> gen_package_versions pkgs
  | Packages -> gen_packages pkgs
