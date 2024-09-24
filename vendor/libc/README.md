# vendor:libc

A (very small) subset of a libc implementation over Odin libraries.
This is mainly intended for use in Odin WASM builds to allow using libraries like box2d, cgltf etc. without emscripten hacks.

You can use this with clang by doing `clang -c --target=wasm32 --sysroot=$(odin root)/vendor/libc` (+ all other flags and inputs).
This will (if all the libc usage of the library is implemented) spit out a `.o` file you can use with the foreign import system.
If you then also make sure this package is included in the Odin side of the project (`@(require) import "vendor:libc"`) you will be able
compile to WASM like Odin expects.

This is currently used by `vendor:box2d`, `vendor:stb/image`, `vendor:stb/truetype`, `vendor:stb/rect_pack`, and `vendor:cgltf`.
You can see how building works by looking at those.
