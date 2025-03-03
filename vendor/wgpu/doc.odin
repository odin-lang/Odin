/*
A cross-platform (and WASM) GPU API.

WASM support is achieved by providing wrappers around the browser native WebGPU API
that are called instead of the [[wgpu-native; https://github.com/gfx-rs/wgpu-native]] library,
the wgpu-native library provides support for all other targets.

**Examples**

You can find a number of examples on [[Odin's official examples repository; https://github.com/odin-lang/examples/tree/master/wgpu]].

**Getting the wgpu-native libraries**

For native support (not the browser), some libraries are required. Fortunately this is
extremely easy, just download them from the [[releases on GitHub; https://github.com/gfx-rs/wgpu-native/releases/tag/v24.0.0.2]].
the bindings are for v24.0.0.2 at the moment.

These are expected in the `lib` folder under the same name as they are released (just unzipped).
By default it will look for a static release version (`wgpu-OS-ARCH-release.a|lib`),
you can set `-define:WGPU_DEBUG=true` for it to look for a debug version,
and use `-define:WGPU_SHARED=true` to look for the shared libraries.

**WASM**

For WASM, the module has to be built with a function table to enable callbacks.
You can do so using `-extra-linker-flags:"--export-table"`.

Being able to allocate is also required (for some auxiliary APIs but also for mapping/unmapping buffers).

You can set the context that is used for allocations by setting the global variable `wpgu.g_context`.
It will default to the `runtime.default_context`.

Have a look at the [[example build file; https://github.com/odin-lang/examples/blob/master/wgpu/glfw-triangle/build_web.sh]] and [[html file; https://github.com/odin-lang/examples/blob/master/wgpu/glfw-triangle/web/index.html]]
to see how it looks when set up, doing the `--import-memory` and the likes
is not strictly necessary but allows your app more memory than the minimal default.

The bindings work on both `-target:js_wasm32` and `-target:js_wasm64p32`.

**SDL Glue**

There is an inner package `sdl2glue` (and `sdl3glue`) that can be used to glue together WGPU and SDL.
It exports one procedure `GetSurface(wgpu.Instance, ^SDL.Window) -> wgpu.Surface`.
The procedure will call the needed target specific procedures and return a surface configured
for the given window.

**GLFW Glue**

There is an inner package `glfwglue` that can be used to glue together WGPU and GLFW.
It exports one procedure `GetSurface(wgpu.Instance, glfw.WindowHandle) -> wgpu.Surface`.
The procedure will call the needed target specific procedures and return a surface configured
for the given window.

Do note that wgpu does not require GLFW, you can use native windows or another windowing library too.
For that you can take inspiration from `glfwglue` on glueing them together.

**GLFW and Wayland**

GLFW supports Wayland from version 3.4 onwards and only if it is compiled with `-DGLFW_EXPOSE_NATIVE_WAYLAND`.

Odin links against your system's glfw library (probably installed through a package manager).
If that version is lower than 3.4 or hasn't been compiled with the previously mentioned define,
you will have to compile glfw from source yourself and adjust the `foreign import` declarations in `vendor:glfw/bindings` to
point to it.
*/
package wgpu
