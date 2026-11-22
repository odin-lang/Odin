// Support file for test_issue_win64_wide_vector_args.odin, built with AVX2.

#if defined(_MSC_VER) && !defined(__clang__)
#include <immintrin.h>
typedef __m256 v8f;
#define LANE(v, i) ((v).m256_f32[i])
#else
typedef float v8f __attribute__((vector_size(32), aligned(32)));
#define LANE(v, i) ((v)[i])
#endif

static int lanes(v8f v, float base) {
	for (int i = 0; i < 8; i++) {
		if (LANE(v, i) != base + (float)i) return 0;
	}
	return 1;
}

static v8f make(float base) {
	v8f v;
	for (int i = 0; i < 8; i++) LANE(v, i) = base + (float)i;
	return v;
}

int c_take_m256(v8f a, double d, v8f b, long long k) {
	return lanes(a, 1) && lanes(b, 11) && d == 5.5 && k == 77;
}

// The pointer to the fifth vector is on the stack.
int c_take_five(v8f a, v8f b, v8f c, v8f d, v8f e) {
	(void)a; (void)b; (void)c; (void)d;
	return lanes(e, 41);
}

// Calls back into Odin, so the Odin side reads what C passed.
extern int odin_take_m256(v8f a, double d, v8f b, long long k);

int c_calls_odin(void) {
	return odin_take_m256(make(1), 5.5, make(11), 77);
}
