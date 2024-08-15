open Astring

let check_pin ~pkg_name ~pin_variable_name ~expected_version ~actual_version
    ~where =
  Printf.printf "  %s=%s\n" pin_variable_name expected_version;
  if not (String.equal expected_version actual_version) then
    Fmt.failwith
      "Expected the pinned version of '%s' should be %s as specified by \
       dkml-runtime-distribution but the actual %s variable in %s is %s@."
      pkg_name expected_version pin_variable_name where actual_version

let check_pins gitlab_ci_yml channel_job yamlvariables =
  List.iter
    (fun (pkg_name, pkg_value, directives) ->
      if
        List.mem Dkml_runtime_distribution.Config.Global_compile directives
        || List.mem Dkml_runtime_distribution.Config.Global_install directives
      then
        (* dune -> PIN_DUNE. dkml-apps -> PIN_DKML_APPS *)
        let pin_variable_name =
          "PIN_"
          ^ String.map (function '-' -> '_' | c -> c)
          @@ String.Ascii.uppercase pkg_name
        in
        let where =
          Fmt.str "the '%s: { variables: ... }' variables object of %a"
            channel_job Fpath.pp gitlab_ci_yml
        in
        match Yaml.Util.find_exn pin_variable_name yamlvariables with
        | None -> Fmt.failwith "No '%s:' found in %s" pin_variable_name where
        | Some yamlpindune ->
            let actual_version = Yaml.Util.to_string_exn yamlpindune in
            (* check PIN_xxx *)
            check_pin ~pkg_name ~pin_variable_name ~expected_version:pkg_value
              ~actual_version ~where)
    Dkml_runtime_distribution.Config.ci_pkgs

let () =
  (* Arg parsing *)
  let gitlab_ci_yml = Sys.argv.(1) in
  let dkml_channel = Sys.argv.(2) in
  Printf.printf "Validating pins of the '.%s' private template job in %s:\n"
    dkml_channel gitlab_ci_yml;
  (* .gitlab-ci.yml parsing *)
  let gitlab_ci_yml = Fpath.v gitlab_ci_yml in
  let yamlroot =
    Rresult.R.error_msg_to_invalid_arg @@ Yaml_unix.of_file gitlab_ci_yml
  in
  let channel_job = "." ^ dkml_channel in
  match Yaml.Util.find_exn channel_job yamlroot with
  | None ->
      Fmt.failwith "No '%s:' object found in the toplevel of %a" channel_job
        Fpath.pp gitlab_ci_yml
  | Some yamljob ->
      (match Yaml.Util.find_exn "variables" yamljob with
      | None ->
          Fmt.failwith "No 'variables:' found in the '%s:' object of %a"
            channel_job Fpath.pp gitlab_ci_yml
      | Some yamlvariables -> check_pins gitlab_ci_yml channel_job yamlvariables);
      print_endline "Validated."
