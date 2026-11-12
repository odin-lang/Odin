package sysinfo

import sys "core:sys/windows"

@(private)
_cpu_features :: proc "contextless" () -> (features: CPU_Features) {
	return _features
}

@(init, private)
_init_cpu_features :: proc "contextless" () {
	has :: proc "contextless" (feature: sys.DWORD) -> bool {
		return bool(sys.IsProcessorFeaturePresent(feature))
	}

	// NOTE: Advanced SIMD and floating-point are mandatory on arm64.
	_features += { .asimd, .floatingpoint }

	if has(sys.PF_ARM_V8_CRYPTO_INSTRUCTIONS_AVAILABLE) {
		_features += { .aes, .pmull, .sha1, .sha256 }
	}
	if has(sys.PF_ARM_V8_CRC32_INSTRUCTIONS_AVAILABLE)   { _features += { .crc32 } }
	if has(sys.PF_ARM_V81_ATOMIC_INSTRUCTIONS_AVAILABLE) { _features += { .lse } }
	if has(sys.PF_ARM_LSE2_AVAILABLE)                    { _features += { .lse2 } }
	if has(sys.PF_ARM_V83_JSCVT_INSTRUCTIONS_AVAILABLE)  { _features += { .jscvt } }
	if has(sys.PF_ARM_V83_LRCPC_INSTRUCTIONS_AVAILABLE)  { _features += { .lrcpc } }
	if has(sys.PF_ARM_SHA3_INSTRUCTIONS_AVAILABLE)       { _features += { .sha3 } }
	if has(sys.PF_ARM_SHA512_INSTRUCTIONS_AVAILABLE)     { _features += { .sha512 } }
	if has(sys.PF_ARM_V82_I8MM_INSTRUCTIONS_AVAILABLE)   { _features += { .i8mm } }
	if has(sys.PF_ARM_V82_FP16_INSTRUCTIONS_AVAILABLE)   { _features += { .fp16, .asimdhp } }
	if has(sys.PF_ARM_V86_BF16_INSTRUCTIONS_AVAILABLE)   { _features += { .bf16 } }
}
