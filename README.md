<img src="logo-slim.png" alt="Odin logo" height="74">

# The Odin Programming Language

Odin is fast, concise, readable, pragmatic and open sourced. It is designed with the intent of replacing C with the following goals:
* simplicity
* high performance
* built for modern systems
* joy of programming
* metaprogramming
* designed for good programmers

## Demonstrations:
* First Talk & Demo
	- [Talk](https://youtu.be/TMCkT-uASaE?t=338)
	- [Demo](https://youtu.be/TMCkT-uASaE?t=1800)
	- [Q&A](https://youtu.be/TMCkT-uASaE?t=5749)
* [Composition & Refactorability](https://www.youtube.com/watch?v=n1wemZfcbXM)
* [Introspection, Modules, and Record Layout](https://www.youtube.com/watch?v=UFq8rhWhx4s)
* [push_allocator & Minimal Dependency Building](https://www.youtube.com/watch?v=f_LGVOAMb78)

## Requirements to build and run

* Windows
* x86-64
* MSVC 2015 installed (C99 support)
* Requires MSVC's link.exe as the linker
	- run `vcvarsall.bat` to setup the path

## Warnings

* This is still highly in development and the language's design is quite volatile.
* Syntax is definitely not fixed

## Roadmap

Not in any particular order

* Custom backend to replace LLVM
	- Improve SSA design to accommodate for lowering to a "bytecode"
	- SSA optimizations
	- COFF generation
	- linker
* Type safe "macros"
* Documentation generator for "Entities"
* Multiple architecture support
* Inline assembly
* Linking options
	- Executable
	- Static/Dynamic Library
* Debug information
	- pdb format too
* Command line tooling
* Compiler internals:
	- Big numbers library

