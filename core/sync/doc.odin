/*
Various synchronization primitives useful to mediate threads' access to shared memory.

To limit or control the threads' access to shared memory typically the following approaches are used:

- Locks
- Lock-free

When using locks, sections of the code that access shared memory (also known as
**critical sections**) are guarded by locks, allowing limited access to threads
and blocking the execution of any other threads.

In lock-free programming the data itself is organized in such a way that threads
don't intervene much. It can be done via segmenting the data between threads,
and/or by using atomic operations.

## Standard vs Atomic Primitives

This package provides two families of synchronization primitives:

**Standard primitives** (`Mutex`, `RW_Mutex`, `Cond`, `Sema`, `Recursive_Mutex`):
These use OS-specific implementations where available. On Windows, they use
native primitives like `SRWLOCK` and `CONDITION_VARIABLE`. On other platforms,
they wrap the atomic implementations internally.

**Atomic primitives** (`Atomic_Mutex`, `Atomic_RW_Mutex`, `Atomic_Cond`,
`Atomic_Sema`, `Atomic_Recursive_Mutex`): These are implemented entirely using
atomic operations and futexes, providing portable, lightweight synchronization
with consistent behavior across all platforms.

**When to use atomic primitives:**

- When cross-platform behavioral consistency is required.
- When memory footprint is critical (e.g., arrays of many locks).
- When using multiple atomic primitives together (e.g., `Atomic_Cond` must be
  used with `Atomic_Mutex`, not the standard `Mutex`).

**When to use standard primitives:**

- For most general use cases.
- When OS-level debugging tools for native primitives are needed.
- When integrating with OS-specific synchronization requirements.
*/
package sync
