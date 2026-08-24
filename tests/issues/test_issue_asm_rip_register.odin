#+build amd64
// `%rip` is in the amd64 register table, but its class carries no width, so the checker's width
// switch reached its `GB_PANIC` default arm and aborted with SIGILL instead of diagnosing. Every
// position that can name a register reached it, including `[%rip + disp]`.
package test_issues

rip_src  :: asm() -> (v: u64) { mov v, %rip; }
rip_dst  :: asm(x: u64) { mov %rip, x; }
rip_mem  :: asm() { mov %rax, [%rip + 8]; }
rip_clob :: asm() [#clobber %rip] { nop; }
rip_in   :: asm(x: u64) [x = %rip] { nop; }
rip_out  :: asm() -> (r: u64) [r = %rip] { nop; }

// the nearest special-purpose register that does carry a class has to keep checking cleanly
rsp_ok :: asm() -> (v: u64) { mov v, %rsp; }
