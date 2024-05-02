package sysinfo

import "core:sys/unix"

@(init, private)
init_cpu_features :: proc "contextless" () {
	@(static) features: CPU_Features
	defer cpu_features = features

	try_set :: proc "contextless" (name: string, feature: CPU_Feature) -> (ok: bool) {
		support: b32
		if ok = unix.sysctlbyname(name, &support); ok && support {
			features += { feature }
		}
		return
	}

	// Docs from Apple: https://developer.apple.com/documentation/kernel/1387446-sysctlbyname/determining_instruction_set_characteristics
	// Features from there that do not have (or I didn't find) an equivalent on Linux are commented out below.

	// Advanced SIMD & floating-point capabilities:
	{
		if !try_set("hw.optional.AdvSIMD", .asimd) {
			try_set("hw.optional.neon", .asimd)
		}

		try_set("hw.optional.floatingpoint", .floatingpoint)

		if !try_set("hw.optional.AdvSIMD_HPFPCvt", .asimdhp) {
			try_set("hw.optional.neon_hpfp", .asimdhp)
		}

		try_set("hw.optional.arm.FEAT_BF16", .bf16)
		// try_set("hw.optional.arm.FEAT_DotProd", .dotprod)

		if !try_set("hw.optional.arm.FEAT_FCMA", .fcma) {
			try_set("hw.optional.armv8_3_compnum", .fcma)
		}

		if !try_set("hw.optional.arm.FEAT_FHM", .fhm) {
			try_set("hw.optional.armv8_2_fhm", .fhm)
		}

		if !try_set("hw.optional.arm.FEAT_FP16", .fp16) {
			try_set("hw.optional.neon_fp16", .fp16)
		}

		try_set("hw.optional.arm.FEAT_FRINTTS", .frint)
		try_set("hw.optional.arm.FEAT_I8MM", .i8mm)
		try_set("hw.optional.arm.FEAT_JSCVT", .jscvt)
		try_set("hw.optional.arm.FEAT_RDM", .rdm)
	}

	// Integer capabilities:
	{
		try_set("hw.optional.arm.FEAT_FlagM", .flagm)
		try_set("hw.optional.arm.FEAT_FlagM2", .flagm2)
		try_set("hw.optional.armv8_crc32", .crc32)
	}

	// Atomic and memory ordering instruction capabilities:
	{
		try_set("hw.optional.arm.FEAT_LRCPC", .lrcpc)
		try_set("hw.optional.arm.FEAT_LRCPC2", .lrcpc2)

		if !try_set("hw.optional.arm.FEAT_LSE", .lse) {
			try_set("hw.optional.armv8_1_atomics", .lse)
		}

		// try_set("hw.optional.arm.FEAT_LSE2", .lse2)
	}

	// Encryption capabilities:
	{
		try_set("hw.optional.arm.FEAT_AES", .aes)
		try_set("hw.optional.arm.FEAT_PMULL", .pmull)
		try_set("hw.optional.arm.FEAT_SHA1", .sha1)
		try_set("hw.optional.arm.FEAT_SHA256", .sha256)

		if !try_set("hw.optional.arm.FEAT_SHA512", .sha512) {
			try_set("hw.optional.armv8_2_sha512", .sha512)
		}

		if !try_set("hw.optional.arm.FEAT_SHA3", .sha3) {
			try_set("hw.optional.armv8_2_sha3", .sha3)
		}
	}

	// General capabilities:
	{
		// try_set("hw.optional.arm.FEAT_BTI", .bti)
		// try_set("hw.optional.arm.FEAT_DPB", .dpb)
		// try_set("hw.optional.arm.FEAT_DPB2", .dpb2)
		// try_set("hw.optional.arm.FEAT_ECV", .ecv)
		try_set("hw.optional.arm.FEAT_SB", .sb)
		try_set("hw.optional.arm.FEAT_SSBS", .ssbs)
	}
}
