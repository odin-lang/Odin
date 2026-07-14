#include <stdint.h>
    #include <stdbool.h>

    // Clang compiles this to a single 32-bit register comparison:
    //     cmp w0, #-1
    // If the caller failed to sign-extend the 8-bit -1 (0xFF) to 32-bit (0xFFFFFFFF),
    // the comparison fails.
    bool test_i8(int8_t val) {
        return val == -1;
    }

    // Clang compiles this to:
    //     cmp w0, #200
    // If the caller did not zero-extend 200 (0xC8) to 32-bit, leaving garbage
    // in the upper bits of w0, this comparison fails.
    bool test_u8(uint8_t val) {
        return val == 200;
    }

    // Clang compiles this to:
    //     cmp w0, #1
    // If the caller did not zero-extend the boolean true (1) to 32-bit,
    // leaving garbage in the upper bits of w0, this comparison fails.
    bool test_bool(bool val) {
        return val == true;
    }
