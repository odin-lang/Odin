package libc_tests

import "core:c/libc"

test_stdio :: proc() {
    c: libc.char = 'C';
    libc.puts("Hello from puts");
    libc.printf("Hello from printf in %c\n", c);
}
test_thread :: proc() {
    thread_proc :: proc "c" (rawptr) -> libc.int {
        libc.printf("Hello from thread");
        return 42;
    }
    thread: libc.thrd_t;
    libc.thrd_create(&thread, thread_proc, nil);
    result: libc.int;
    libc.thrd_join(thread, &result);
    libc.printf(" %d\n", result);
}

jmp: libc.jmp_buf;
test_sjlj :: proc() {
    if libc.setjmp(&jmp) != 0 {
        libc.printf("Hello from longjmp\n");
        return;
    }
    libc.printf("Hello from setjmp\n");
    libc.longjmp(&jmp, 1);
}
test_signal :: proc() {
    handler :: proc "c" (sig: libc.int) {
        libc.printf("Hello from signal handler\n");
    }
    libc.signal(libc.SIGABRT, handler);
    libc.raise(libc.SIGABRT);
}
test_atexit :: proc() {
    handler :: proc "c" () {
        libc.printf("Hello from atexit\n");
    }
    libc.atexit(handler);
}
main :: proc() {
    test_stdio();
    test_thread();
    test_sjlj();
    test_signal();
    test_atexit();
}