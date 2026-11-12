package test_internal

import "base:intrinsics"
import "core:testing"

// Copies with a run-time length up to 16 bytes are inlined at -o:speed. Every length must copy exactly
// what `memmove` would, also when the regions overlap in either direction.

@(private="file")
mem_copy_n :: #force_no_inline proc(dst, src: [^]byte, n: int) {
	intrinsics.mem_copy(dst, src, n)
}

@(private="file")
mem_copy_non_overlapping_n :: #force_no_inline proc(dst, src: [^]byte, n: int) {
	intrinsics.mem_copy_non_overlapping(dst, src, n)
}

@(private="file")
copy_n :: #force_no_inline proc(dst, src: [^]byte, n: int) {
	copy(dst[:n], src[:n])
}

@(private="file")
ref_memmove :: proc(dst, src: [^]byte, n: int) {
	if uintptr(dst) > uintptr(src) {
		for i := n-1; i >= 0; i -= 1 {
			dst[i] = src[i]
		}
	} else {
		for i in 0..<n {
			dst[i] = src[i]
		}
	}
}

@(private="file")
fill :: proc(buf: []byte, seed: int) {
	for &b, i in buf {
		b = byte(i*31 + seed*7 + 1)
	}
}

@(test)
test_mem_copy_small_lengths :: proc(t: ^testing.T) {
	Copy :: #type proc(dst, src: [^]byte, n: int)
	copies := [?]Copy{mem_copy_n, mem_copy_non_overlapping_n, copy_n}

	got, want: [128]byte
	src: [128]byte
	fill(src[:], 3)

	failures := 0
	for copy_proc, ci in copies {
		for n in 0..=40 {
			for dst_off in 0..<8 {
				for src_off in 0..<8 {
					fill(got[:], 5)
					fill(want[:], 5)
					copy_proc(&got[16+dst_off], &src[16+src_off], n)
					ref_memmove(&want[16+dst_off], &src[16+src_off], n)
					if got != want {
						testing.expectf(t, false, "copy %v: n=%v dst_off=%v src_off=%v", ci, n, dst_off, src_off)
						failures += 1
						if failures > 10 {
							return
						}
					}
				}
			}
		}
	}

	// Overlapping regions, only for the procedures with `memmove` semantics
	for copy_proc, ci in ([]Copy{mem_copy_n, copy_n}) {
		for n in 0..=40 {
			for shift in -20..=20 {
				fill(got[:], 9)
				fill(want[:], 9)
				copy_proc(&got[40+shift], &got[40], n)
				ref_memmove(&want[40+shift], &want[40], n)
				if got != want {
					testing.expectf(t, false, "overlapping copy %v: n=%v shift=%v", ci, n, shift)
					failures += 1
					if failures > 10 {
						return
					}
				}
			}
		}
	}
}
