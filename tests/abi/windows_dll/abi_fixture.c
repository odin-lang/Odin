#include <stdint.h>

#define ABI_EXPORT __declspec(dllexport)

typedef struct Abi_Result {
	int64_t total;
	double weighted;
	uint32_t tag;
	uint32_t padding;
} Abi_Result;

typedef int64_t (*Abi_Callback)(
	int64_t, int64_t, int64_t, int64_t, int64_t,
	int64_t, int64_t, int64_t, int64_t, int64_t
);

ABI_EXPORT int64_t abi_sum10(
	int64_t a0, int64_t a1, int64_t a2, int64_t a3, int64_t a4,
	int64_t a5, int64_t a6, int64_t a7, int64_t a8, int64_t a9
) {
	return a0 + a1 + a2 + a3 + a4 + a5 + a6 + a7 + a8 + a9;
}

ABI_EXPORT double abi_weighted10(
	double a0, double a1, double a2, double a3, double a4,
	double a5, double a6, double a7, double a8, double a9
) {
	return a0 + 2*a1 + 3*a2 + 4*a3 + 5*a4 +
	       6*a5 + 7*a6 + 8*a7 + 9*a8 + 10*a9;
}

ABI_EXPORT Abi_Result abi_make_result(int64_t base, double scale, uint32_t tag) {
	Abi_Result result = {
		base + 42,
		scale * 2.0,
		tag ^ 0xa5a5a5a5u,
		0,
	};
	return result;
}

ABI_EXPORT int64_t abi_call_callback(Abi_Callback callback, int64_t seed) {
	return callback(
		seed + 0, seed + 1, seed + 2, seed + 3, seed + 4,
		seed + 5, seed + 6, seed + 7, seed + 8, seed + 9
	);
}
