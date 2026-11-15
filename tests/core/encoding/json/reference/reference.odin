package encoding_json_reference

// A frozen copy of `core:encoding/json` (types, tokenizer, parser, validator and unmarshal) taken
// at f9f544ec4, before any performance work. Only the package name has been changed.
//
// It is the oracle for `tests/core/encoding/json/differential` and the baseline for
// `tests/benchmark/encoding/json`. Do not edit these files: any behaviour the current package
// does not reproduce exactly is a regression, quirks included.
