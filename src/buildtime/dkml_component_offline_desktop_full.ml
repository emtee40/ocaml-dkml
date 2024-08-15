open Dkml_install_api
open Dkml_install_register
open Bos

let execute_install ctx =
  Staging_ocamlrun_api.spawn_ocamlrun ctx
    Cmd.(
      v
        (Fpath.to_string
           (ctx.Context.path_eval
              "%{offline-desktop-full:share-generic}%/install.bc"))
      %% of_list (Array.to_list (Log_config.to_args ctx.Context.log_config))
      % "--withdkml-source-dir"
      % Fpath.to_string (ctx.Context.path_eval "%{staging-withdkml:share-abi}%")
      % "--global-install-dir"
      % Fpath.to_string
          (ctx.Context.path_eval "%{staging-desktop-full:share-abi}%/install")
      % "--global-compile-dir"
      % Fpath.to_string
          (ctx.Context.path_eval "%{staging-desktop-full:share-abi}%/compile")
      % "--target-dir"
      % Fpath.to_string (ctx.Context.path_eval "%{prefix}%"))

let execute_uninstall ctx =
  Staging_ocamlrun_api.spawn_ocamlrun ctx
    Cmd.(
      v
        (Fpath.to_string
           (ctx.Context.path_eval
              "%{offline-desktop-full:share-generic}%/uninstall.bc"))
      %% of_list (Array.to_list (Log_config.to_args ctx.Context.log_config))
      % "--target-dir"
      % Fpath.to_string (ctx.Context.path_eval "%{prefix}%"))

let register () =
  let reg = Component_registry.get () in
  Component_registry.add_component reg
    (module struct
      include Default_component_config

      let component_name = "offline-desktop-full"

      let install_depends_on =
        [ "staging-ocamlrun"; "staging-desktop-full"; "staging-withdkml" ]

      let uninstall_depends_on = [ "staging-ocamlrun" ]

      let install_user_subcommand ~component_name:_ ~subcommand_name ~fl ~ctx_t
          =
        let doc = "Install Full flavor of desktop executables" in
        Dkml_install_api.Forward_progress.Continue_progress
          ( Cmdliner.Cmd.v
              (Cmdliner.Cmd.info subcommand_name ~doc)
              Cmdliner.Term.(const execute_install $ ctx_t),
            fl )

      let uninstall_user_subcommand ~component_name:_ ~subcommand_name ~fl
          ~ctx_t =
        let doc = "Uninstall Full flavor of desktop executables" in
        Dkml_install_api.Forward_progress.Continue_progress
          ( Cmdliner.Cmd.v
              (Cmdliner.Cmd.info subcommand_name ~doc)
              Cmdliner.Term.(const execute_uninstall $ ctx_t),
            fl )
    end)
