//+build 386, amd64
package sys_cpu

_cache_line_size :: 64;

cpuid :: proc(ax, cx: u32) -> (eax, ebc, ecx, edx: u32) {
	return expand_to_tuple(asm(u32, u32) -> struct{eax, ebc, ecx, edx: u32} {
		"cpuid",
		"={ax},={bx},={cx},={dx},{ax},{cx}",
	}(ax, cx));
}

xgetbv :: proc() -> (eax, edx: u32) {
	return expand_to_tuple(asm(u32) -> struct{eax, edx: u32} {
		"xgetbv",
		"={ax},={dx},{cx}",
	}(0));
}

_init :: proc() {
	is_set :: proc(hwc: u32, value: u32) -> bool {
		return hwc&value != 0;
	}

	initialized = true;

	max_id, _, _, _ := cpuid(0, 0);

	if max_id < 1 {
		return;
	}

	_, _, ecx1, edx1 := cpuid(1, 0);

	x86.has_sse2 = is_set(26, edx1);

	x86.has_sse3      = is_set(0, ecx1);
	x86.has_pclmulqdq = is_set(1, ecx1);
	x86.has_ssse3     = is_set(9, ecx1);
	x86.has_fma       = is_set(12, ecx1);
	x86.has_sse41     = is_set(19, ecx1);
	x86.has_sse42     = is_set(20, ecx1);
	x86.has_popcnt    = is_set(23, ecx1);
	x86.has_aes       = is_set(25, ecx1);
	x86.has_os_xsave  = is_set(27, ecx1);
	x86.has_rdrand    = is_set(30, ecx1);

	os_supports_avx := false;
	if x86.has_os_xsave {
		eax, _ := xgetbv();
		os_supports_avx = is_set(1, eax) && is_set(2, eax);
	}

	x86.has_avx = is_set(28, ecx1) && os_supports_avx;

	if max_id < 7 {
		return;
	}

	_, ebx7, _, _ := cpuid(7, 0);
	x86.has_bmi1   = is_set(3, ebx7);
	x86.has_avx2   = is_set(5, ebx7) && os_supports_avx;
	x86.has_bmi2   = is_set(8, ebx7);
	x86.has_erms   = is_set(9, ebx7);
	x86.has_rdseed = is_set(18, ebx7);
	x86.has_adx    = is_set(19, ebx7);
}
