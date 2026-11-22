// Support file for test_issue_sysv_wide_vectors.odin, built with AVX2.

typedef float v8f  __attribute__((vector_size(32), aligned(32)));
typedef float v16f __attribute__((vector_size(64), aligned(64)));
typedef struct { v8f v; } w8f;
typedef struct { double x, y; } d2;

static int lanes8(v8f v, float base) {
	for (int i = 0; i < 8; i++) {
		if (v[i] != base + (float)i) return 0;
	}
	return 1;
}

static int lanes16(v16f v, float base) {
	for (int i = 0; i < 16; i++) {
		if (v[i] != base + (float)i) return 0;
	}
	return 1;
}

static v8f make8(float base) {
	v8f v;
	for (int i = 0; i < 8; i++) v[i] = base + (float)i;
	return v;
}

static v16f make16(float base) {
	v16f v;
	for (int i = 0; i < 16; i++) v[i] = base + (float)i;
	return v;
}

// Four vectors in YMM0-3, then the struct in XMM4:XMM5.
int c_take_ymm(v8f a, v8f b, v8f c, v8f d, d2 s, double e) {
	return lanes8(a, 1) && lanes8(b, 11) && lanes8(c, 21) && lanes8(d, 31) && s.x == 1.5 && s.y == 2.5 && e == 3.5;
}

// Eight vectors fill YMM0-7, and the ninth goes on the stack.
int c_take_nine(v8f a, v8f b, v8f c, v8f d, v8f e, v8f f, v8f g, v8f h, v8f i) {
	(void)a; (void)b; (void)c; (void)d; (void)e; (void)f; (void)g;
	return lanes8(h, 71) && lanes8(i, 81);
}

// A struct of one vector is passed as the vector.
int c_take_wrapped(w8f a, double d) {
	return lanes8(a.v, 1) && d == 4.5;
}

// Wider than YMM: memory, which takes no register from the double after it.
int c_take_v16(v16f a, double d) {
	return lanes16(a, 1) && d == 5.5;
}

v8f  c_ret_v8f(float base)  { return make8(base); }
w8f  c_ret_w8f(float base)  { w8f r; r.v = make8(base); return r; }
v16f c_ret_v16f(float base) { return make16(base); }

// Calls back into Odin, so the Odin side reads what C passed, and C reads what Odin returned.
extern int  odin_take_ymm(v8f a, v8f b, v8f c, v8f d, d2 s, double e);
extern int  odin_take_wrapped(w8f a, double d);
extern v8f  odin_ret_v8f(float base);
extern w8f  odin_ret_w8f(float base);
extern v16f odin_ret_v16f(float base);

int c_calls_odin(void) {
	d2 s = {1.5, 2.5};
	w8f w; w.v = make8(1);
	if (!odin_take_ymm(make8(1), make8(11), make8(21), make8(31), s, 3.5)) return 1;
	if (!odin_take_wrapped(w, 4.5)) return 2;
	if (!lanes8(odin_ret_v8f(41), 41)) return 3;
	if (!lanes8(odin_ret_w8f(51).v, 51)) return 4;
	if (!lanes16(odin_ret_v16f(61), 61)) return 5;
	return 0;
}
