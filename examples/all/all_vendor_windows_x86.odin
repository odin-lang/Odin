#+build windows amd64, windows i386
package all

// NOTE: These packages link libraries that are only bundled as x64 builds for Windows, so they panic on Windows arm64.

@(require) import "vendor:compress/lz4"
@(require) import "vendor:box2d"

// NOTE: Only x86-64 builds of WGPU Native are bundled, see `vendor/wgpu/doc.odin` for other architectures.
@(require) import "vendor:wgpu/glfwglue"
@(require) import "vendor:wgpu/sdl2glue"
@(require) import "vendor:wgpu"
