# lib/ocaml/camlheader
# lib/ocaml/camlheader_ur
/lib[/\\]ocaml[/\\][A-Za-z0-9_]*$/ { print }

# Note: macOS awk will raise an error in the above line:
#
#   awk: nonterminated character class lib[
#    source line number 3 source file scripts/stdlib.awk
#    context is
# 	   >>> /lib[/ <<< 
#
# Use stdlib-unixonly.awk for macOS.

# lib/ocaml/stdlib__Int32.cmi
# lib/ocaml/weak.ml
# lib\ocaml\weak.mli
/lib[/\\]ocaml[/\\][A-Za-z0-9_]*[.][a-z]*$/ { print }

# lib/ocaml/caml/callback.h
# lib/ocaml/stublibs/dllnums.dll
/lib[/\\]ocaml[/\\][A-Za-z0-9_-]*[/\\][A-Za-z0-9_-]*[.][a-z0-9]*$/ { print }
