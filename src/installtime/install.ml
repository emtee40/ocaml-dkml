let exe_ext = if Sys.win32 then ".exe" else ""
let plus_exe s = if Sys.win32 then s ^ ".exe" else s

let fpath_esc_pp fmt v =
  (* Need Z:\\source not Z:\source on Windows *)
  Fmt.pf fmt "%s" (String.escaped (Fpath.to_string v))

let fpath_forwardslash_pp fmt v =
  (* Need Z:/source not Z:\source on Windows *)
  Fmt.pf fmt "%s"
    (String.map (function '\\' -> '/' | c -> c) (Fpath.to_string v))

let ld_conf_bytecode target_dir =
  Format.asprintf {|
%a
%a
|} fpath_forwardslash_pp
    Fpath.(target_dir / "desktop" / "bc" / "lib" / "ocaml" / "stublibs")
    fpath_forwardslash_pp
    Fpath.(target_dir / "desktop" / "bc" / "lib" / "ocaml")
  |> String.trim

(** Like:

  {v
  destdir="Z:\\source\\dkml\\build\\pkg\\bump\\.ci\\o\\PR\\lib"
  path="Z:\\source\\dkml\\build\\pkg\\bump\\.ci\\o\\PR\\lib"
  ocamlc="ocamlc.exe"
  ocamlopt="ocamlopt.exe"
  ocamldep="ocamldep.exe"
  ocamldoc="ocamldoc.exe"
  v}
*)
let findlib_conf ?precompiled target_dir =
  let tdir =
    if precompiled = Some () then Fpath.(target_dir / "desktop" / "bc")
    else target_dir
  in
  let ocamlopt_line =
    if precompiled = Some () then ""
    else Format.sprintf {|ocamlopt="ocamlopt%s"|} exe_ext
  in
  Format.asprintf
    {|
destdir="%a"
path="%a"
stdlib="%a"
ldconf="%a"
ocamlc="ocamlc%s"
ocamldep="ocamldep%s"
ocamldoc="ocamldoc%s"
%s
|}
    fpath_esc_pp
    Fpath.(tdir / "lib")
    fpath_esc_pp
    Fpath.(tdir / "lib")
    fpath_esc_pp
    Fpath.(tdir / "lib" / "ocaml")
    fpath_esc_pp
    Fpath.(tdir / "lib" / "ocaml" / "ld.conf")
    exe_ext exe_ext exe_ext ocamlopt_line
  |> String.trim

let topfind target_dir =
  Format.asprintf
    {|
(* $Id$ -*- tuareg -*- *)

(* For Ocaml-3.03 and up, so you can do: #use "topfind" and get a
 * working findlib toploop.
 *)

#directory "%a";;
  (* OCaml-4.00 requires to have #directory before we load anything *)

#directory "+compiler-libs";;
  (* For OCaml-4.00. This directory will be later removed from path *)

(* First test whether findlib_top is already loaded. If not, load it now.
 * The test works by executing the toplevel phrase "Topfind.reset" and
 * checking whether this causes an error.
 *)
let exec_test s =
  let l = Lexing.from_string s in
  let ph = !Toploop.parse_toplevel_phrase l in
  let fmt = Format.make_formatter (fun _ _ _ -> ()) (fun _ -> ()) in
  try
    Toploop.execute_phrase false fmt ph
  with
      _ -> false
in
let is_native =
  (* one of the few observable differences... *)
  Gc.((get()).stack_limit) = 0 in
let suffix =
  if is_native then "cmxs" else "cma" in
if not(exec_test "Topfind.reset;;") then (
  Topdirs.dir_load Format.err_formatter ("%a." ^ suffix);
  Topdirs.dir_load Format.err_formatter ("%a." ^ suffix);
);
;;

#remove_directory "+compiler-libs";;

(* The following is always executed. It is harmless if findlib was already
 * initialized
 *)

let is_native =
  (* one of the few observable differences... *)
  Gc.((get()).stack_limit) = 0 in
let pred =
  if is_native then "native" else "byte" in
Topfind.add_predicates [ pred; "toploop" ];
Topfind.don't_load ["findlib"];
Topfind.announce();;
|}
    fpath_esc_pp
    Fpath.(target_dir / "desktop" / "bc" / "lib" / "findlib")
    fpath_esc_pp
    Fpath.(target_dir / "desktop" / "bc" / "lib" / "findlib" / "findlib")
    fpath_esc_pp
    Fpath.(target_dir / "desktop" / "bc" / "lib" / "findlib" / "findlib_top")
  |> String.trim

let reword_to_string = Fmt.str "%a" Rresult.R.pp_msg
let to_string_err v = Rresult.R.reword_error reword_to_string v

let copy_dir_and_get_file_relpaths ~src ~dst =
  let ( let* ) = Rresult.R.bind in
  let ret = ref [] in
  let* () =
    Diskuvbox.walk_down ~max_depth:10 ~from_path:src
      ~f:
        (fun ~depth:_ ~path_attributes:_ -> function
          | Root | Directory _ -> Ok ()
          | File relpath ->
              ret := relpath :: !ret;
              Ok ())
      ()
  in
  let* () = Diskuvbox.copy_dir ~src ~dst () in
  Ok !ret

let install_res ~withdkml_source_dir ~global_install_dir ~global_compile_dir
    ~target_dir =
  Dkml_install_api.Forward_progress.lift_result __POS__ Fmt.lines
    Dkml_install_api.Forward_progress.stderr_fatallog
  @@
  let ( let* ) = Rresult.R.bind in
  (* Direct copies into target directory *)
  let* file_relpaths1 =
    copy_dir_and_get_file_relpaths ~src:withdkml_source_dir ~dst:target_dir
  in
  let* file_relpaths2 =
    copy_dir_and_get_file_relpaths ~src:global_install_dir ~dst:target_dir
  in
  (* Capture the direct copies into desktop/install.json *)
  let desktop_dir = Fpath.(target_dir / "desktop") in
  let* (_already_created : bool) =
    Bos.OS.Dir.create desktop_dir |> to_string_err
  in
  let fail_on_partial = function
    | `Ok -> Ok ()
    | `Partial -> Rresult.R.error_msg "Unexpected `Partial during JSON encoding"
  in
  let* () =
    let res =
      Bos.OS.File.with_oc
        Fpath.(desktop_dir / "install.json")
        (fun oc () ->
          let enc = Jsonm.encoder ~minify:false (`Channel oc) in
          let* () = Jsonm.encode enc (`Lexeme `As) |> fail_on_partial in
          let* () =
            List.fold_left
              (fun prev relpath ->
                match prev with
                | Error e -> Error e
                | Ok () ->
                    Jsonm.encode enc
                      (`Lexeme (`String (Fpath.to_string relpath)))
                    |> fail_on_partial)
              (Ok ())
              (file_relpaths1 @ file_relpaths2)
          in
          let* () = Jsonm.encode enc (`Lexeme `Ae) |> fail_on_partial in
          let* () = Jsonm.encode enc `End |> fail_on_partial in
          Ok ())
        ()
    in
    match res with
    | Ok (Ok ()) -> Ok ()
    | Ok (Error e) -> Error (reword_to_string e)
    | Error e -> Error (reword_to_string e)
  in
  (* The [global-compile] goes into desktop/bc *)
  let bc_dir = Fpath.(desktop_dir / "bc") in
  let* () = Diskuvbox.copy_dir ~src:global_compile_dir ~dst:bc_dir () in
  (* Overwrite desktop/bc/lib/ocaml/topfind *)
  let topfind_loc = Fpath.(bc_dir / "lib" / "ocaml" / "topfind") in
  let topfind_contents = topfind target_dir in
  let* () = Bos.OS.File.write topfind_loc topfind_contents |> to_string_err in
  (* Overwrite desktop/bc/lib/ocaml/ld.conf *)
  let ld_conf_loc = Fpath.(bc_dir / "lib" / "ocaml" / "ld.conf") in
  let ld_conf_contents = ld_conf_bytecode target_dir in
  let* () = Bos.OS.File.write ld_conf_loc ld_conf_contents |> to_string_err in
  (* We want binaries to behave as if they were compiled in-place. So we
     use with-dkml.exe as a shim.

     IMPORTANT DESIGN NOTE:
        Confer: https://github.com/diskuv/dkml-installer-ocaml/issues/83

     We place the shims like ocamlfind and even ordinary precompiled executables like
     ocamllex into <DkMLHome>/usr/bin.

     That is because install-ocaml-compiler.sh of dkml-runtimescripts ... which
     is executed during [dkml init] or the first invocation of [with-dkml] ...
     will copy native executables from the OCaml compiler (ocamlc, ocamlopt, ocamllex, etc.)
     into <DkMLHome>/bin. And then the opam package [ocaml-system] will add
     a PATH+=<DkMLHome>/bin to the opam switch because that is where
     ocamlc and ocamlopt live.

     We absolutely do not want shims like ocamlfind to be in the PATH of an
     opam switch because the global ocamlfind will have the wrong findlib locations!
     Of course, if the opam switch has its own ocamlfind, then there is no issue,
     but many opam switches will not have ocamlfind. And if tools like Dune detect
     the global ocamlfind the compilation will be wrong.
  *)
  let shim binary =
    let* () =
      Diskuvbox.copy_file
        ~src:Fpath.(withdkml_source_dir / "bin" / plus_exe "with-dkml")
        ~dst:Fpath.(target_dir / "usr" / "bin" / plus_exe binary)
        ()
    in
    Diskuvbox.copy_file
      ~src:Fpath.(bc_dir / "bin" / plus_exe binary)
      ~dst:Fpath.(target_dir / "usr" / "bin" / plus_exe (binary ^ "-real"))
      ()
  in
  let copy src =
    Diskuvbox.copy_file ~src
      ~dst:Fpath.(target_dir / "usr" / "bin" / basename src)
      ()
  in
  let* () =
    let rec helper = function
      | Ok [] -> Ok ()
      | Ok (hd :: tl) when Fpath.has_ext ".dll" hd || Fpath.has_ext ".so" hd ->
          (* Shared libraries in bin should be copied. Windows in particular
             needs DLLs like sqlite3.dll in the PATH. *)
          let* () = copy hd in
          helper (Ok tl)
      | Ok (hd :: tl)
        when Fpath.has_ext ".obj" hd || Fpath.has_ext ".manifest" hd ->
          (* Skip [default_amd64.manifest] and [flexdll_msvc64.obj], etc.
             b/c not needed for bytecode offline installations *)
          helper (Ok tl)
      | Ok (hd :: tl) ->
          (* .../bin/utop.exe -> utop *)
          let* () =
            match Fpath.(rem_ext hd |> filename) with
            | "safe_camlp4" ->
                (* copy shellscript.
                   overwritten if not [setup-userprofile.ps1 -Offline]. *)
                copy hd
            | ("ocaml" | "ocamlc" | "ocamlcp") as program ->
                (* ocaml executables that need a shim.
                   overwritten if not [setup-userprofile.ps1 -Offline]. *)
                shim program
            | "ocamlcmt" | "ocamldebug" | "ocamldep" | "ocamldoc" | "ocamllex"
            | "ocamlmktop" | "ocamlobjinfo" | "ocamlrun" | "ocamlprof"
            | "ocamlyacc" ->
                (* standalone ocaml executables that don't need shims
                   that are needed in bytecode offline installations.
                   overwritten if not [setup-userprofile.ps1 -Offline]. *)
                copy hd
            | "flexlink" | "ocamlmklib" | "ocamlnat" | "ocamlopt" | "ocamloptp"
              ->
                (* ocaml executables that are not copied b/c they are not
                   needed for bytecode offline installations *)
                Ok ()
            | program ->
                (* If not special cased above (like utop), make a shim for it *)
                shim program
          in
          helper (Ok tl)
      | Error v -> Error (reword_to_string v)
    in
    let bin_files = Bos.OS.Dir.contents Fpath.(bc_dir / "bin") in
    helper bin_files
  in
  (* Create usr/lib/ *)
  let usr_lib = Fpath.(target_dir / "usr" / "lib") in
  let* () =
    Bos.OS.Dir.create usr_lib
    |> Rresult.R.map (fun (_already_created : bool) -> ())
    |> to_string_err
  in
  (* Write usr/lib/findlib-{precompiled,enduser}.conf.
     "usr/" is not part of dkml-component-ocamlcompiler's
     [uninstall_controldir] which automatically deletes directories like "lib/"
     during install. *)
  let conf_loc = Fpath.(usr_lib / "findlib-precompiled.conf") in
  let conf_contents = findlib_conf ~precompiled:() target_dir in
  let* () = Bos.OS.File.write conf_loc conf_contents |> to_string_err in
  let conf_loc = Fpath.(usr_lib / "findlib-enduser.conf") in
  let conf_contents = findlib_conf target_dir in
  Bos.OS.File.write conf_loc conf_contents |> to_string_err

let install (_ : Dkml_install_api.Log_config.t) withdkml_source_dir
    global_install_dir global_compile_dir target_dir =
  match
    install_res ~withdkml_source_dir ~global_install_dir ~global_compile_dir
      ~target_dir
  with
  | Completed | Continue_progress ((), _) -> ()
  | Halted_progress ec ->
      exit (Dkml_install_api.Forward_progress.Exit_code.to_int_exitcode ec)

let withdkml_source_dir_t =
  let x =
    Cmdliner.Arg.(
      required
      & opt (some dir) None
      & info ~doc:"with-dkml source path" [ "withdkml-source-dir" ])
  in
  Cmdliner.Term.(const Fpath.v $ x)

let global_install_dir_t =
  let x =
    Cmdliner.Arg.(
      required
      & opt (some dir) None
      & info ~doc:"global-install source path" [ "global-install-dir" ])
  in
  Cmdliner.Term.(const Fpath.v $ x)

let global_compile_dir_t =
  let x =
    Cmdliner.Arg.(
      required
      & opt (some dir) None
      & info ~doc:"global-compile source path" [ "global-compile-dir" ])
  in
  Cmdliner.Term.(const Fpath.v $ x)

let target_dir_t =
  let x =
    Cmdliner.Arg.(
      required
      & opt (some string) None
      & info ~doc:"Target path" [ "target-dir" ])
  in
  Cmdliner.Term.(const Fpath.v $ x)

let setup_log style_renderer level =
  Fmt_tty.setup_std_outputs ?style_renderer ();
  Logs.set_level level;
  Logs.set_reporter (Logs_fmt.reporter ());
  Dkml_install_api.Log_config.create ?log_config_style_renderer:style_renderer
    ?log_config_level:level ()

let setup_log_t =
  Cmdliner.Term.(
    const setup_log $ Fmt_cli.style_renderer () $ Logs_cli.level ())

let cli () =
  let open Cmdliner in
  let t =
    Term.(
      const install $ setup_log_t $ withdkml_source_dir_t $ global_install_dir_t
      $ global_compile_dir_t $ target_dir_t)
  in
  let info =
    Cmd.info "install.bc" ~doc:"Install desktop binaries and bytecode"
  in
  exit (Cmd.eval (Cmd.v info t))
