#+build windows amd64, windows i386
package all_sdl3

// NOTE: Only x86-64 builds of WGPU Native are bundled, see `vendor/wgpu/doc.odin` for other architectures.
import wgpu_sdl3_glue "vendor:wgpu/sdl3glue"

_ :: wgpu_sdl3_glue
