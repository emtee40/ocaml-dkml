open Dkml_install_api
open Dkml_install_register
open Bos

let execute_install ctx =
  if not (Context.Abi_v2.is_windows ctx.Context.target_abi_v2) then
    Staging_ocamlrun_api.spawn_ocamlrun ctx
      Cmd.(
        v
          (Fpath.to_string
             (ctx.Context.path_eval "%{_:share-generic}%/unix_install.bc"))
        % "-target"
        % Fpath.to_string (ctx.Context.path_eval "%{_:share-abi}%/bin/curl"))

let register () =
  let reg = Component_registry.get () in
  Component_registry.add_component reg
    (module struct
      include Default_component_config

      let component_name = "staging-curl"

      let install_depends_on = [ "staging-ocamlrun" ]

      let install_user_subcommand ~component_name:_ ~subcommand_name ~fl ~ctx_t
          =
        let doc = "Install Unix utilities" in
        Dkml_install_api.Forward_progress.Continue_progress
          ( Cmdliner.Cmd.v
              (Cmdliner.Cmd.info subcommand_name ~doc)
              Cmdliner.Term.(const execute_install $ ctx_t),
            fl )
    end)
