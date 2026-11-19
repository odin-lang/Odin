#+build !windows
#+build !linux
package benchmark_codegen

// No CPU pinning: macOS has no affinity API.
@(require_results)
prepare_process :: proc(cpu: int) -> bool {
	return cpu < 0
}
