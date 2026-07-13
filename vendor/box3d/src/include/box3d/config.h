// SPDX-FileCopyrightText: 2026 Erin Catto
// SPDX-License-Identifier: MIT

#pragma once

// Box3D compile-time options.
//
// Normally set by the CMake BOX3D_* options. If you build Box3D without its
// CMake (dropping the sources into another project), set them here so the
// library and your code agree. Edit this file, or keep your settings elsewhere
// and point Box3D at them from your build:
//
//   #define BOX3D_USER_CONFIG "my_box3d_config.h"
//
// A define passed on the compiler command line still wins over this file.

// Large world mode. Stores world positions in double precision. Affects ABI.
//#define BOX3D_DOUBLE_PRECISION

// Build the scalar fallback instead of SSE2/NEON.
//#define BOX3D_DISABLE_SIMD

// Enable internal validation in debug builds.
//#define BOX3D_VALIDATE

// Decorate the public API with your own export macro instead of Box3D's
// box3d_EXPORTS/BOX3D_DLL scheme, for example when compiling Box3D into another
// shared library. A single value cannot switch between dllexport and dllimport,
// so this suits embedding more than shipping Box3D as its own DLL.
//#define BOX3D_EXPORT MYENGINE_API

