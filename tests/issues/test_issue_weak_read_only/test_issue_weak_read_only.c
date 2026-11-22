// Support file for test_issue_weak_read_only.odin.
//
// Replaces the Odin `weak` procedure `issue_weak_hook` at link time with a body that writes the global it was given.
// It stands in for any other body: for this signature the Odin convention passes `v` by pointer in the first argument
// register, keeps `context` in a callee-saved register, and returns in the first return register, the same as C.

typedef struct { long long a, b, c; } Big;

extern Big issue_weak_g_big;

// 1: the parameter kept its value while the global it was passed from changed
long long issue_weak_hook(Big *v) {
	long long before = v->a;
	issue_weak_g_big.a = 99;
	return v->a == before;
}

int issue_weak_linked(void) {
	return 1;
}
