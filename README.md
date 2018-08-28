<p align="center">
    <img src="misc/logo-slim.png" alt="Odin logo" height="120">
    <br/>
    A fast, concise, readable, pragmatic and open sourced programming language.
    <br/>
    <br/>
    <a href="https://github.com/odin-lang/odin/releases/latest">
        <img src="https://img.shields.io/github/release/odin-lang/odin.svg">
    </a>
    <a href="https://github.com/odin-lang/odin/releases/latest">
        <img src="https://img.shields.io/badge/platforms-Windows%20|%20Linux%20|%20macOS-green.svg">
    </a>
    <a href="https://github.com/odin-lang/odin/blob/master/LICENSE">
        <img src="https://img.shields.io/github/license/odin-lang/odin.svg">
    </a>
</p>

# The Odin Programming Language

The Odin programming language is fast, concise, readable, pragmatic and open sourced. It is designed with the intent of replacing C with the following goals:
* simplicity
* high performance
* built for modern systems
* joy of programming
* metaprogramming

Website: [https://odin.handmade.network/](https://odin.handmade.network/)

```go
package main

import "core:fmt"

main :: proc() {
	program := "+ + * 😃 - /";
	accumulator := 0;

	for token in program {
		switch token {
		case '+': accumulator += 1;
		case '-': accumulator -= 1;
		case '*': accumulator *= 2;
		case '/': accumulator /= 2;
		case '😃': accumulator *= accumulator;
		case: // Ignore everything else
		}
	}

	fmt.printf("The program \"%s\" calculates the value %d\n",
	           program, accumulator);
}

```

## Demonstrations:
* First Talk & Demo
	- [Talk](https://youtu.be/TMCkT-uASaE?t=338)
	- [Demo](https://youtu.be/TMCkT-uASaE?t=1800)
	- [Q&A](https://youtu.be/TMCkT-uASaE?t=5749)
* [Composition & Refactorability](https://www.youtube.com/watch?v=n1wemZfcbXM)
* [Introspection, Modules, and Record Layout](https://www.youtube.com/watch?v=UFq8rhWhx4s)
* [push_allocator & Minimal Dependency Building](https://www.youtube.com/watch?v=f_LGVOAMb78)
* [when, for & procedure overloading](https://www.youtube.com/watch?v=OzeOekzyZK8)
* [Context Types, Unexported Entities, Labelled Branches](https://www.youtube.com/watch?v=CkHVwT1Qk-g)
* [Bit Fields, i128 & u128, Syntax Changes](https://www.youtube.com/watch?v=NlTutcLyF64)
* [Default and Named Arguments; Explicit Parametric Polymorphism](https://www.youtube.com/watch?v=-XQZE6S6zUU)
* [Loadsachanges](https://www.youtube.com/watch?v=ar0vFMoMtrI)

## Documentation
* [Tutorial](https://odin.handmade.network/wiki/3329-odin_tutorial)
* [Frequently Asked Questions](https://github.com/odin-lang/Odin/wiki/Frequently-Asked-Questions-(FAQ))

## Requirements to build and run

- Windows
	* x86-64
	* MSVC 2010 installed (C++11 support)
	* [LLVM binaries](https://github.com/odin-lang/Odin/releases/tag/llvm-windows) for `opt.exe`, `llc.exe`, and `lld-link.exe`
	* Requires MSVC's link.exe as the linker
		* run `vcvarsall.bat` to setup the path

- MacOS
	* x86-64
	* LLVM explicitly installed (`brew install llvm`)
	* XCode installed (for the linker)

- GNU/Linux
	* x86-64
	* Build tools (ld)
	* LLVM installed
	* Clang installed (temporary - this is Calling the linker for now)

## Warnings

* This is still highly in development and the language's design is quite volatile.
* Syntax is not fixed.
