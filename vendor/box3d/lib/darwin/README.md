# Box3D MacOS build

Build steps:

```
cmake --preset macos -DCMAKE_OSX_DEPLOYMENT_TARGET="11.0" -DCMAKE_OSX_ARCHITECTURES="arm64;x86_64"
cmake --build --preset macos-release -DCMAKE_OSX_DEPLOYMENT_TARGET="11.0" -DCMAKE_OSX_ARCHITECTURES="arm64;x86_64"
```

This makes a fat binary that works on ARM and Intel MacOS. And it sets the target (`-minimum-os-version` in Odin) to 11.0 (Odin's default).
