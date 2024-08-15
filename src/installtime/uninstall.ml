open Bos

let portable_delete_file target_fp =
  let ( let* ) = Rresult.R.bind in
  (* [doc from diskuvbox]
     [tracks https://github.com/dbuenzli/bos/issues/98]
     For Windows, can't write without turning off read-only flag.
     In fact, you can still get Permission Denied even after turning
     off read-only flag, perhaps because Windows has a richer
     permissions model than POSIX. So we remove the file
     after turning off read-only *)
  if Sys.win32 then
    let* exists = OS.File.exists target_fp in
    if exists then
      let* () = OS.Path.Mode.set target_fp 0o644 in
      OS.File.delete target_fp
    else Ok ()
  else OS.File.delete target_fp

let delete_from_install_json ~jsonfile ~target_dir =
  let ( let* ) = Result.bind in
  let* exists = OS.File.exists jsonfile in
  let rec helper dec =
    match Jsonm.decode dec with
    | `Await -> Rresult.R.error_msg "Unexpected `Await during JSON decode"
    | `Error e -> Rresult.R.error_msgf "%a" Jsonm.pp_error e
    | `Lexeme (`Name relpath) ->
        (* Don't trust the possibly modified install.json. Normalize
           to remove any ".." path segments, and make sure relative. *)
        let relpath = Fpath.v relpath |> Fpath.normalize in
        if Fpath.is_rel relpath then
          let* () = portable_delete_file Fpath.(target_dir // relpath) in
          helper dec
        else (
          Logs.warn (fun l ->
              l "Skipping bad supposed install file %a" Fpath.pp relpath);
          helper dec)
    | `Lexeme _ -> helper dec
    | `End -> Ok ()
  in
  if exists then
    let* contents = OS.File.read jsonfile in
    let dec = Jsonm.decoder (`String contents) in
    helper dec
  else Ok ()

let uninstall_res ~target_dir =
  Dkml_install_api.uninstall_directory_onerror_exit ~id:"a1d66eb6"
    ~dir:Fpath.(target_dir / "desktop")
    ~wait_seconds_if_stuck:300.;
  Dkml_install_api.Forward_progress.lift_result __POS__ Fmt.lines
    Dkml_install_api.Forward_progress.stderr_fatallog
  @@
  let ( let* ) = Rresult.R.bind in
  (* Anything that was copied directly into the target directory during
     installation should now be deleted. *)
  (* OLD (don't want to have to copy staging files to uninstaller.
       let delete_copied_files from_path =
       Diskuvbox.walk_down ~from_path
         ~f:
           (fun ~depth:_ ~path_attributes:_ -> function
             | Root | Directory _ -> Ok ()
             | File relpath ->
                 portable_file_delete Fpath.(target_dir // relpath)
                 |> Install.to_string_err)
         ()
     in
     let* () = delete_copied_files withdkml_source_dir in
     let* () = delete_copied_files global_install_dir in *)
  let* () =
    delete_from_install_json
      ~jsonfile:Fpath.(target_dir / "desktop" / "install.json")
      ~target_dir
    |> Install.to_string_err
  in
  (* ocamlfind, utop and utop-full in DkML 1.x were in usr/bin but in DkML 2.x
     moved to bin. They are orphaned in usr/bin. *)
  let delete_usr_bin x =
    portable_delete_file Fpath.(target_dir / "usr" / "bin" / Install.plus_exe x)
    |> Install.to_string_err
  in
  let* () = delete_usr_bin "ocamlfind" in
  let* () = delete_usr_bin "utop" in
  let* () = delete_usr_bin "utop-full" in
  Ok ()

let uninstall (_ : Dkml_install_api.Log_config.t) target_dir =
  match uninstall_res ~target_dir with
  | Completed | Continue_progress ((), _) -> ()
  | Halted_progress ec ->
      exit (Dkml_install_api.Forward_progress.Exit_code.to_int_exitcode ec)

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
  let t = Term.(const uninstall $ setup_log_t $ target_dir_t) in
  let info =
    Cmd.info "uninstall.bc" ~doc:"Uninstall desktop binaries and bytecode"
  in
  exit (Cmd.eval (Cmd.v info t))
