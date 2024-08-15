open Bos

type t = { sexp : Sexplib0.Sexp.t }

let create_from_system_confdir ~unit_name ~dkml_confdir_exe =
  let confdir =
    match
      OS.Cmd.run_out Cmd.(v (Fpath.to_string dkml_confdir_exe))
      |> OS.Cmd.out_string ~trim:true
      |> OS.Cmd.success
    with
    | Ok s -> s
    | Error e ->
        Dkml_install_api.Forward_progress.stderr_fatallog ~id:"af18f230"
          (Fmt.str "%a" Rresult.R.pp_msg e);
        exit
          (Dkml_install_api.Forward_progress.Exit_code.to_int_exitcode
             Exit_transient_failure)
  in
  let conffile = Fpath.(to_string (v confdir / (unit_name ^ ".sexp"))) in
  {
    sexp =
      (if Sys.file_exists conffile then
       Sexplib.Sexp.load_sexp ~strict:true conffile
      else Sexplib.Sexp.unit);
  }

let create_from_sexp sexp = { sexp }
