open Astring
open Jingoo

let cachebust = 1

let static_vars = [ ("cachebust", Jg_types.Tstr (string_of_int cachebust)) ]

(* GitLab CI/CD constraints: https://docs.gitlab.com/ee/ci/yaml/index.html#cachekey *)
let sanitize_key =
  String.map (function
    | '-' -> '-'
    | c when not (Char.Ascii.is_alphanum c) -> '_'
    | c -> c)

(** The compact cache key is a tradeoff between accuracy and brevity.

    In GitHub Actions we can perform a hash over a
    long list of cache key components; that is both accurate and short.
    
    In GitLab CI/CD we cannot perform any expressions over the cache key
    components. Even worse, the cache key is verbatim as a directory
    on the Windows/Ubuntu/macOS build machine. To keep the cache key short
    we need to find proxy values for the cache key components that may
    not be 100% accurate but are mostly accurately.
    
    The expectation is that GitLab CI/CD uses the compact cache key, while
    GitHub Actions uses the accurate cache keys. *)
let cachekey_compact ~input:_ ~matrix ~commitref =
  [ sanitize_key Version.dune_project_version; matrix "abi_pattern"; commitref ]

let cachekey_opambin ~read_script ~input:_ ~matrix =
  match read_script "setup-dkml.sh" with
  | None -> failwith "The script setup-dkml.sh was not found"
  | Some script ->
      [
        (* The DEFAULT_DISKUV_OPAM_REPOSITORY_TAG is inside setup-dkml.sh. We just take the
           md5 of it so we implicitly have a dependency on DEFAULT_DISKUV_OPAM_REPOSITORY_TAG *)
        Digest.string script |> Digest.to_hex |> String.with_range ~len:6;
        matrix "dkml_host_abi";
        matrix "opam_abi";
      ]

let cachekey_vsstudio ~input:_ ~matrix =
  [
    matrix "abi_pattern";
    matrix "vsstudio_arch";
    matrix "vsstudio_hostarch";
    matrix "vsstudio_dir";
    matrix "vsstudio_vcvarsver";
    matrix "vsstudio_winsdkver";
    matrix "vsstudio_msvspreference";
    matrix "vsstudio_cmakegenerator";
  ]

let cachekey_ci_inputs ~input ~matrix:_ =
  [
    input "OCAML_COMPILER";
    input "DISKUV_OPAM_REPOSITORY";
    input "DKML_COMPILER";
    input "CONF_DKML_CROSS_TOOLCHAIN";
  ]

let gh_cachekeys read_script =
  let join = String.concat ~sep:"-" in
  let input s = Printf.sprintf "${{ inputs.%s }}" s in
  let matrix s = Printf.sprintf "${{ steps.full_matrix_vars.outputs.%s }}" s in
  let commitref = "${{ github.ref_name }}" in
  [
    ( "gh_cachekey_compact",
      Jg_types.Tstr (join (cachekey_compact ~input ~matrix ~commitref)) );
    ( "gh_cachekey_opambin",
      Jg_types.Tstr (join (cachekey_opambin ~read_script ~input ~matrix)) );
    ( "gh_cachekey_ci_inputs",
      Jg_types.Tstr (join (cachekey_ci_inputs ~input ~matrix)) );
    ( "gh_cachekey_vsstudio",
      Jg_types.Tstr (join (cachekey_vsstudio ~input ~matrix)) );
  ]

let gl_cachekeys read_script =
  let join = String.concat ~sep:"-" in
  let input s = Printf.sprintf "${%s}" s in
  let matrix s = Printf.sprintf "${%s}" s in
  let commitref = "${CI_COMMIT_REF_SLUG}" in
  [
    ( "gl_cachekey_compact",
      Jg_types.Tstr (join (cachekey_compact ~input ~matrix ~commitref)) );
    ( "gl_cachekey_opambin",
      Jg_types.Tstr (join (cachekey_opambin ~read_script ~input ~matrix)) );
    ( "gl_cachekey_ci_inputs",
      Jg_types.Tstr (join (cachekey_ci_inputs ~input ~matrix)) );
    ( "gl_cachekey_vsstudio",
      Jg_types.Tstr (join (cachekey_vsstudio ~input ~matrix)) );
  ]
