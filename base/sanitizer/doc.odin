/*
The `sanitizer` package implements various procedures for interacting with sanitizers
from user code.

An odin project can be linked with various sanitizers to help identify various different
bugs. These sanitizers are:

## Address

Enabled with `-sanitize:address` when building an odin project.

The address sanitizer (asan) is a runtime memory error detector used to help find common memory
related bugs. Typically asan interacts with libc but Odin code can be marked up to interact
with the asan runtime to extend the memory error detection outside of libc using this package.
For more information about asan see: https://clang.llvm.org/docs/AddressSanitizer.html

Procedures can be made exempt from asan when marked up with @(no_sanitize_address)

## Memory

Enabled with `-sanitize:memory` when building an odin project.

The memory sanitizer is another runtime memory error detector with the sole purpose to catch the
use of uninitialized memory. This is not a very common bug in Odin as by default everything is
set to zero when initialised (ZII).
For more information about the memory sanitizer see: https://clang.llvm.org/docs/MemorySanitizer.html

## Thread

Enabled with `-sanitize:thread` when building an odin project.

The thread sanitizer is a runtime data race detector. It can be used to detect if multiple threads
are concurrently writing and accessing a memory location without proper syncronisation.
For more information about the thread sanitizer see: https://clang.llvm.org/docs/ThreadSanitizer.html

*/
package sanitizer

