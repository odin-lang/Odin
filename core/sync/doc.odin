/*
Synchronization primitives

This package implements various synchronization primitives that can be used to
synchronize threads' access to shared memory.

To limit or control the threads' access to shared memory typically the
following approaches are used:

- Locks
- Lock-free

When using locks, sections of the code that access shared memory (also known as
**critical sections**) are guarded by locks, allowing limited access to threads
and blocking the execution of any other threads.

In lock-free programming the data itself is organized in such a way that threads
don't intervene much. It can be done via segmenting the data between threads,
and/or by using atomic operations.
*/
package sync
