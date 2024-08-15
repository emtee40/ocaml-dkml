# Caution:
# - Always test on macOS. Their awk is very limited (maybe it is a BSD thing?)
#   and can't do >>> /lib[/]ocaml/ <<< without failing with
#      awk: nonterminated character class lib[

# lib/ocaml/camlheader
# lib/ocaml/camlheader_ur
/lib\/ocaml\/[A-Za-z0-9_]*$/ { print }

# lib/ocaml/stdlib__Int32.cmi
# lib/ocaml/weak.ml
/lib\/ocaml\/[A-Za-z0-9_]*[.][a-z]*$/ { print }

# lib/ocaml/caml/callback.h
# lib/ocaml/stublibs/dllnums.dll
/lib\/ocaml\/[A-Za-z0-9_-]*\/[A-Za-z0-9_-]*[.][a-z0-9]*$/ { print }
