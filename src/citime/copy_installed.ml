open Bos

let usage () =
  prerr_endline
    {|usage: dkml-desktop-copy-installed --file-list FILE_LIST --opam-switch-prefix OPAM_SWITCH_PREFIX --output-dir OUTPUT_DIR

The FILE_LIST should be a file with the opam show --readonly --list-files response for one or more opam
packages. For example:

  opam show --readonly --list-files dune

The FILE_LIST should look like the following:

  /Volumes/Source/dkml-component-desktop/.ci/o/dkml/bin/dune
  /Volumes/Source/dkml-component-desktop/.ci/o/dkml/bin/dune-real
  ...
  /Volumes/Source/dkml-component-desktop/.ci/o/dkml/lib/dune
  /Volumes/Source/dkml-component-desktop/.ci/o/dkml/lib/dune/META
  ...
  /Volumes/Source/dkml-component-desktop/.ci/o/dkml/man/man1/dune.1

It may contain lines like the following (confer
https://github.com/ocaml/opam/blob/d282c1d4ed442eeffdb3f81acaa26bf60a2be61f/src/client/opamListCommand.ml#L611-L612):

  /Volumes/Source/dkml-component-desktop/.ci/o/dkml/bin/dune (absent)
  /Volumes/Source/dkml-component-desktop/.ci/o/dkml/bin/dune-real (modified since)

The processing is as follows:
1. Any directories in the output like dkml/lib/dune above will be ignored.
2. The OPAM_SWITCH_PREFIX ancestor directories are stripped from the output.
3. The remaining relative path (ex. bin/dune) is copied to OUTPUT_DIR
   (ex. OUTPUT_DIR/bin/dune). Any intermediate directories that don't exist
   will be created.
|}

let badarg s =
  usage ();
  prerr_endline s;
  exit 2

let copy_file ~opam_switch_prefix ~output_dir ~abspath relpath =
  match
    Diskuvbox.copy_file
      ~src:Fpath.(opam_switch_prefix // relpath)
      ~dst:Fpath.(output_dir // relpath)
      ()
  with
  | Ok () -> Format.printf "Copied %a@." Fpath.pp relpath
  | Error msg ->
      failwith
        (Format.asprintf
           "The path %a was calculated to be the relative path %a under the \
            opam switch prefix %a. However it could not be copied under %a: %s"
           Fpath.pp abspath Fpath.pp relpath Fpath.pp opam_switch_prefix
           Fpath.pp output_dir msg)

let copy_path_if_file ~opam_switch_prefix ~output_dir abspath () =
  let abspath = Fpath.v abspath in
  match Fpath.relativize ~root:opam_switch_prefix abspath with
  | None ->
      failwith
        (Format.asprintf "The path %a was not within the opam switch prefix %a"
           Fpath.pp abspath Fpath.pp opam_switch_prefix)
  | Some relpath -> (
      match OS.File.exists abspath with
      | Ok true -> copy_file ~opam_switch_prefix ~output_dir ~abspath relpath
      | Ok false -> ()
      | Error msg ->
          failwith
            (Format.asprintf "The path %a could not be read: %a" Fpath.pp
               abspath Rresult.R.pp_msg msg))

let copy ~file_list ~opam_switch_prefix ~output_dir =
  let ch = open_in (Fpath.to_string file_list) in
  let modified_since_suffix = " (modified since)" in
  Fun.protect
    ~finally:(fun () -> close_in ch)
    (fun () ->
      try
        while true do
          let abspath = input_line ch in
          match String.trim abspath with
          | "" -> ()
          (* https://github.com/ocaml/opam/blob/d282c1d4ed442eeffdb3f81acaa26bf60a2be61f/src/client/opamListCommand.ml#L611-L612 *)
          | s when Astring.String.is_suffix ~affix:" (absent)" s ->
            ()
          | s when Astring.String.is_suffix ~affix:modified_since_suffix s ->
            let abspath' = Astring.String.with_range
              ~len:(String.length s - String.length modified_since_suffix)
              s
            in
            copy_path_if_file ~opam_switch_prefix ~output_dir abspath' ()
          | abspath' ->
              copy_path_if_file ~opam_switch_prefix ~output_dir abspath' ()
        done
      with End_of_file -> ())

let () =
  (* parse *)
  let opam_switch_prefix = ref "" in
  let file_list = ref "" in
  let output_dir = ref "" in
  let anon _s =
    failwith
      "No command line arguments are allowed for dkml-desktop-copy-installed"
  in
  Arg.parse
    [
      ( "--file-list",
        Set_string file_list,
        "The file with the output of 'opam show --list-files PACKAGES" );
      ( "--opam-switch-prefix",
        Set_string opam_switch_prefix,
        "The opam switch prefix. Typically it is available in the \
         OPAM_SWITCH_PREFIX environment variable, or as the response from \
         `opam var prefix`" );
      ("--output-dir", Set_string output_dir, "The output directory");
    ]
    anon "dkml-desktop-copy-installed";
  if String.equal !opam_switch_prefix "" then
    badarg "Missing --opam-switch-prefix OPAM_SWITCH_PREFIX";
  if String.equal !file_list "" then badarg "Missing --file-list FILE_LIST";
  if String.equal !output_dir "" then badarg "Missing --output-dir OUTPUT_DIR";
  copy ~file_list:(Fpath.v !file_list)
    ~opam_switch_prefix:(Fpath.v !opam_switch_prefix)
    ~output_dir:(Fpath.v !output_dir)
