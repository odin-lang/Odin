#+build wasm32, wasm64p32
package sysinfo

@(private)
_cpu_core_count :: proc "contextless" () -> (physical: int, logical: int, ok: bool) {
	return 0, 0, false
}

CPU_Feature  :: enum u64 {}
CPU_Features :: distinct bit_set[CPU_Feature; u64]

@(private)
_cpu_features :: proc "contextless" () -> (features: CPU_Features) {
	return {}
}

@(private)
_cpu_name :: proc() -> (name: string) {
	return "wasm32" when ODIN_ARCH == .wasm32 else "wasm64p32"
}