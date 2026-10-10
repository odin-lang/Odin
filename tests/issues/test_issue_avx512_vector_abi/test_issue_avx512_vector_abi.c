// Support file for test_issue_avx512_vector_abi.odin, built with -mavx512f.

#include <stdint.h>

typedef uint32_t v16u32 __attribute__((vector_size(64)));
typedef double   v8f64  __attribute__((vector_size(64)));
typedef uint32_t v32u32 __attribute__((vector_size(128)));

v16u32 c_make_v16u32(uint32_t k) { v16u32 v; for (int i = 0; i < 16; i++) v[i] = k + i;  return v; }
v8f64  c_make_v8f64(double k)    { v8f64 v;  for (int i = 0; i < 8;  i++) v[i] = k * i;  return v; }
v32u32 c_make_v32u32(uint32_t k) { v32u32 v; for (int i = 0; i < 32; i++) v[i] = k + i;  return v; }

// Calls back into Odin, so the C side reads what Odin returned.
extern v16u32 odin_make_v16u32(uint32_t k);
extern v8f64  odin_make_v8f64(double k);
extern v32u32 odin_make_v32u32(uint32_t k);

uint64_t c_sum_odin_vectors(uint32_t k) {
	uint64_t s = 0;
	v16u32 a = odin_make_v16u32(k);       for (int i = 0; i < 16; i++) s = s*31 + a[i];
	v8f64  b = odin_make_v8f64((double)k); for (int i = 0; i < 8;  i++) s = s*31 + (uint64_t)b[i];
	v32u32 c = odin_make_v32u32(k);       for (int i = 0; i < 32; i++) s = s*31 + c[i];
	return s;
}
