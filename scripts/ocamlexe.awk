# bin/ocamllex.byte.exe
# bin/ocamllex.opt.exe
{ redundant_exe=0 }
/[.]byte$/ { redundant_exe=1 }
/[.]byte[.]exe$/ { redundant_exe=1 }
/[.]opt$/ { redundant_exe=1 }
/[.]opt[.]exe$/ { redundant_exe=1 }

# bin/ocamlmklib.exe
redundant_exe==0 && /bin[/\\][A-Za-z0-9_]*[.]exe$/ { print }
redundant_exe==0 && /bin[/\\][A-Za-z0-9_]*$/ { print }

# Note: macOS awk will raise an error in the above lines. See stdlib.awk

# bin/flexdll_msvc64.obj
# bin/flexdll_initer_msvc64.obj
redundant_exe==0 && /bin[/\\][A-Za-z0-9_]*[.]obj$/ { print }

# bin/default_amd64.manifest
redundant_exe==0 && /bin[/\\][A-Za-z0-9_]*[.]manifest$/ { print }