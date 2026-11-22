// Support file for test_issue_wasm_c_vectors.odin, built for wasm32 without and with simd128.

typedef float v2f __attribute__((vector_size(8)));
typedef float v4f __attribute__((vector_size(16)));
typedef float v8f __attribute__((vector_size(32)));

static int lanes2(v2f v, float base) { return v[0] == base && v[1] == base + 1; }
static int lanes4(v4f v, float base) { for (int i = 0; i < 4; i++) if (v[i] != base + (float)i) return 0; return 1; }
static int lanes8(v8f v, float base) { for (int i = 0; i < 8; i++) if (v[i] != base + (float)i) return 0; return 1; }

static v4f make4(float base) { v4f v; for (int i = 0; i < 4; i++) v[i] = base + (float)i; return v; }

int c_take_v2f(v2f a, double d)        { return lanes2(a, 1) && d == 1.5; }
int c_take_v4f(v4f a, double d, v4f b) { return lanes4(a, 1) && lanes4(b, 11) && d == 2.5; }
int c_take_v8f(v8f a, int k)           { return lanes8(a, 21) && k == 7; }

v4f c_ret_v4f(float base) { return make4(base); }
v8f c_ret_v8f(float base) { v8f v; for (int i = 0; i < 8; i++) v[i] = base + (float)i; return v; }

// Calls back into Odin, so the Odin side reads what C passed, and C reads what Odin returned.
extern int odin_take_v4f(v4f a, double d, v4f b);
extern v4f odin_ret_v4f(float base);

int c_calls_odin(void) {
	return odin_take_v4f(make4(1), 2.5, make4(11)) && lanes4(odin_ret_v4f(31), 31);
}
