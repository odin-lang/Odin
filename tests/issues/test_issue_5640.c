// Tests issue: https://github.com/odin-lang/Odin/issues/5640

#include <stdint.h>
#include <stdbool.h>

typedef struct {
    uint32_t a;
    uint32_t b;
    uint32_t c;
} MyStruct;

bool test_stack_next(
    int64_t r0, int64_t r1, int64_t r2, int64_t r3,
    int64_t r4, int64_t r5, int64_t r6, int64_t r7,
    MyStruct s,
    int32_t next_arg
) {
    return next_arg == 999;
}
