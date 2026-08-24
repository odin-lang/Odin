#+build amd64
// `Entity_AsmTemplate` was added to `ENTITY_KINDS` but not to the two `[Entity_Count]` tables in
// `src/docs.cpp`, so its slot was zero-filled: ordering `0` and a null name. `odin doc` and
// `odin check -show-unused` printed an `asm` template under an empty category header, and passed
// the null name to a `%s`.
package test_issues

DOC_CONST :: 1

doc_proc :: proc() {}

doc_asm :: asm() { nop; }

doc_asm_32 :: asm(a: i32) -> (v: i32) { mov v, a; }
doc_asm_64 :: asm(a: i64) -> (v: i64) { mov v, a; }
doc_asm_group :: asm { doc_asm_32, doc_asm_64 }
