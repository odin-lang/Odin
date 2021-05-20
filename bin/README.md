# The Odin Programming Language

## Setup

Odin currently supports x86-64 and ARM64 at the moment (64-bit), relies on LLVM for code generation and an external linker.

In addition, the following platform-specific steps are necessary:

- Windows
    * Have Visual Studio installed (MSVC 2010 or later, for the linker)
    * Open a valid command prompt:
        * **Basic:** run the `x64 Native Tools Command Prompt for VS2017` shortcut bundled with VS 2017, or
        * **Advanced:** run `vcvarsall.bat x64` from a blank `cmd` session

- MacOS
    * Have LLVM explicitly installed (`brew install llvm`)
    * Have XCode installed (version X.X or later, for linking)
    * Make sure the LLVM binaries and the linker are added to your `$PATH` environmental variable

- GNU/Linux
    * Have Clang installed (version X.X or later, for linking)
    * Make sure the LLVM binaries and the linker are added to your `$PATH` environmental variable

Then build the compiler by calling `build.bat` (Windows) or `make` (Linux/MacOS). This will automatically run the demo program if successful.

**Notes for \*Nix Systems:**: The compiler currently relies on the `core` and `shared` library collection being relative to the compiler executable, by default. Installing the compiler in the usual sense (to `/usr/local/bin` or similar) is therefore not as straight forward as you need to make sure the mentioned libraries are available. As a result, it is recommended to either simply explicitly invoke the compiler with `/path/to/odin` in your preferred build system, or `set ODIN_ROOT=/path/to/odin_root`.


Please read the [Getting Started Guide](https://github.com/odin-lang/Odin/wiki#getting-started-with-odin) for more information.
