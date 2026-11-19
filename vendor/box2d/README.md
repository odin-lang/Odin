![Box2D Logo](https://box2d.org/images/logo.svg)

# Box2D

Odin bindings for [Box2D](https://box2d.org) v3.2.0, a 2D physics engine for games by Erin Catto, under the
[MIT license](LICENSE).

The bindings are single precision (no `BOX2D_DOUBLE_PRECISION`), where `Pos` is a `Vec2` and `WorldTransform` a `Transform`.
`box2d.odin`, `collision.odin`, `types.odin`, `base.odin` and `id.odin` are generated from the API description that
Box2D ships (`api/box2d_api.json`); `lib.odin`, `constants.odin`, `id_helpers.odin` and `math_functions.odin` are written
by hand, including the functions that Box2D's headers define inline.

Box2D selects AVX2 or SSE2 at run time, so there is a single library per platform. The libraries in `lib` are built by
`build_box2d.sh`: a Windows one (`box2d_windows_amd64.lib`), a universal macOS one (`box2d_darwin.a`) and two for WASM
(`box2d_wasm.o`, and `box2d_wasm_simd.o` which lets the compiler use `simd128`). On Linux there are none, run
`build_box2d.sh` to build `box2d_other_amd64.a` (or `box2d_other.a` for other CPUs).

Some notes:

- Box2D creates and destroys worlds in a global array without locking, so do not do that from several threads at once.
- Box2D 3.2 runs its own worker threads when a world has a `workerCount` above 1 and no task callbacks. A WASM world is
  single threaded, leave `workerCount` at 1.
- The 3.2 release notes list the API changes from 3.1:
  https://github.com/erincatto/box2d/blob/v3.2.0/docs/release_notes_v320.md

## Ports, wrappers, and bindings

- https://github.com/odin-lang/Odin/tree/master/vendor/box2d
- https://github.com/EnokViking/Box2DBeef
- https://github.com/HolyBlackCat/box2cpp
