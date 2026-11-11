#+build amd64
// An output's register is already written, so naming it in '#clobber' is an error: each template here is one
package test_issue_asm_clobber_pinned_output

same_register :: asm(x: u64) -> (r: u64) [r = %rax, #clobber %rax] { mov r, x }
sub_register  :: asm(x: u32) -> (r: u32) [r = %eax, #clobber %rax] { mov r, x }
tied_output   :: asm(x: u64) -> (r: u64) [x -> r = %rdx, #clobber %rdx] { add r, 1 }
