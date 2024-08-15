type t = { sexp : Sexplib0.Sexp.t }

val create_from_system_confdir :
  unit_name:string -> dkml_confdir_exe:Fpath.t -> t
(** [create_from_system_confdir ~unit_name ~dkml_confdir_exe] reads the
    configuration unit named [unit_name ^ ".sexp"] in the system
    configuration directory printed by the executable [dkml_confdir_exe] *)

val create_from_sexp : Sexplib0.Sexp.t -> t
