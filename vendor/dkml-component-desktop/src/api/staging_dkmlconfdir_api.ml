module Conf_loader = Conf_loader

let dkml_confdir_exe ctx =
  ctx.Dkml_install_api.Context.path_eval
    "%{staging-dkmlconfdir:share-abi}%/bin/dkml-confdir.exe"
