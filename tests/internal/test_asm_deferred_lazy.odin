#+build amd64
#+lazy
package test_internal

// Only named from the `asm` templates of `test_asm_deferred.odin`, and so only checked when their bodies are

ASM_DEFERRED_LAZY_K :: 40

Asm_Deferred_Lazy_U32 :: distinct u32

asm_deferred_lazy_add :: asm(a: u64) -> (r: u64) [a -> r] { add r, ASM_DEFERRED_LAZY_K }
