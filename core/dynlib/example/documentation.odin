/*

This directory comprises two distinct packages:
- `lib.odin` is dynamic library exporting a number of symbols.
- `example.odin` is a separate package, demonstrating how to dynamically load the symbols in `lib.odin`.

To try this out, first compile `lib.odin`, like so:
- `odin build lib.odin -file -build-mode:dll`

Then build and run the example package:
- `odin run example.odin -file`.

If everything goes well, you should see output resembling the following (the addresses may differ):

(Initial DLL Load) ok: true. 3 symbols loaded from lib.dll (0x7FFB3DD90000).
42 + 42 = 84
84 - 13 = 71
hellope = 42
(DLL Reload) ok: true. 3 symbols loaded from lib.dll (0x7FFB3DD90000).
42 + 42 = 84
84 - 13 = 71
hellope = 42

*/
package dynlib_example_documentation