package sys_cpu

#assert(ODIN_USE_LLVM_API);

Cache_Line_Pad :: struct {_: [_cache_line_size]byte};

initialized: bool;

x86: struct {
	_: Cache_Line_Pad,
	has_aes:       bool, // AES hardware implementation (AES NI)
	has_adx:       bool, // Multi-precision add-carry instruction extensions
	has_avx:       bool, // Advanced vector extension
	has_avx2:      bool, // Advanced vector extension 2
	has_bmi1:      bool, // Bit manipulation instruction set 1
	has_bmi2:      bool, // Bit manipulation instruction set 2
	has_erms:      bool, // Enhanced REP for MOVSB and STOSB
	has_fma:       bool, // Fused-multiply-add instructions
	has_os_xsave:  bool, // OS supports XSAVE/XRESTOR for saving/restoring XMM registers.
	has_pclmulqdq: bool, // PCLMULQDQ instruction - most often used for AES-GCM
	has_popcnt:    bool, // Hamming weight instruction POPCNT.
	has_rdrand:    bool, // RDRAND instruction (on-chip random number generator)
	has_rdseed:    bool, // RDSEED instruction (on-chip random number generator)
	has_sse2:      bool, // Streaming SIMD extension 2 (always available on amd64)
	has_sse3:      bool, // Streaming SIMD extension 3
	has_ssse3:     bool, // Supplemental streaming SIMD extension 3
	has_sse41:     bool, // Streaming SIMD extension 4 and 4.1
	has_sse42:     bool, // Streaming SIMD extension 4 and 4.2
	_: Cache_Line_Pad,
};


init :: proc() {
	_init();
}
