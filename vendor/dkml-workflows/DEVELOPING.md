# Developing

```console
$ opam install . --deps-only --yes

# If you need IDE support
$ opam install ocaml-lsp-server ocamlformat ocamlformat-rpc --yes

$ opam exec -- dune runtest
$ opam exec -- dune runtest --auto-promote
```
