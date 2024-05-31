# WGPU

A cross-platform (and WASM) GPU API.

WASM support is achieved by providing wrappers around the browser native WebGPU API
that are called instead of the [wgpu-native](https://github.com/gfx-rs/wgpu-native) library,
the wgpu-native library provides support for all other targets.

Have a look at the `example/` directory for the rendering of a basic triangle.

## Getting the wgpu-native libraries

For native support (not the browser), some libraries are required. Fortunately this is
extremely easy, just download them from the [releases on GitHub](https://github.com/gfx-rs/wgpu-native/releases/tag/v0.19.4.1),
the bindings are for v0.19.4.1 at the moment.

These are expected in the `lib` folder under the same name as they are released (just unzipped).
By default it will look for a static release version (`wgpu-OS-ARCH-release.a|lib`),
you can set `-define:WGPU_DEBUG=true` for it to look for a debug version,
and use `-define:WGPU_SHARED=true` to look for the shared libraries.

## WASM

For WASM, the module has to be built with a function table to enable callbacks.
You can do so using `-extra-linker-flags:"--export-table"`.

Being able to allocate is also required (for some auxiliary APIs but also for mapping/unmapping buffers).

You can set the context that is used for allocations by setting the global variable `wpgu.g_context`.
It will default to the `runtime.default_context`.

Again, have a look at the `example/` and how it is set up, doing the `--import-memory` and the likes
is not strictly necessary but allows your app more memory than the minimal default.

The bindings work on both `-target:js_wasm32` and `-target:js_wasm64p32`.

## GLFW Glue

There is an inner package `glfwglue` that can be used to glue together WGPU and GLFW.
It exports one procedure `GetSurface(wgpu.Instance, glfw.WindowHandle) -> glfw.Surface`.
The procedure will call the needed target specific procedures and return a surface configured
for the given window.

To support Wayland on Linux, you need to have GLFW compiled to support it, and use
`-define:WGPU_GFLW_GLUE_SUPPORT_WAYLAND=true` to enable the package to check for Wayland.

Do note that wgpu does not require GLFW, you can use native windows or another windowing library too.
For that you can take inspiration from `glfwglue` on glueing them together.
