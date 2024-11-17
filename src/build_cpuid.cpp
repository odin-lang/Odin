#if !defined(GB_COMPILER_MSVC)
	#if defined(GB_CPU_X86)
		#include <cpuid.h>
	#endif
#endif

gb_internal void odin_cpuid(int leaf, int result[]) {
	#if defined(GB_CPU_ARM) || defined(GB_CPU_RISCV)
		return;

	#elif defined(GB_CPU_X86)
	
		#if defined(GB_COMPILER_MSVC)
			__cpuid(result, leaf);
		#else
			__get_cpuid(leaf, (unsigned int*)&result[0], (unsigned int*)&result[1], (unsigned int*)&result[2], (unsigned int*)&result[3]);
		#endif

	#endif
}

gb_internal bool should_use_march_native() {
	#if !defined(GB_CPU_X86)
		return false;

	#else

		int cpu[4];
		odin_cpuid(0x1, &cpu[0]); // Get feature information in ECX + EDX

		bool have_popcnt = cpu[2] & (1 << 23); // bit 23 in ECX = popcnt
		return !have_popcnt;

	#endif
}