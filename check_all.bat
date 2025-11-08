@echo off

if "%1" == "" (
	echo Checking darwin_amd64 - expect vendor:cgltf panic
	odin check examples\all -vet -vet-tabs -strict-style -vet-style -warnings-as-errors -target:darwin_amd64
	echo Checking darwin_arm64 - expect vendor:cgltf panic
	odin check examples\all -vet -vet-tabs -strict-style -vet-style -warnings-as-errors -target:darwin_arm64
	echo Checking linux_i386
	odin check examples\all -vet -vet-tabs -strict-style -vet-style -warnings-as-errors -target:linux_i386
	echo Checking linux_amd64
	odin check examples\all -vet -vet-tabs -strict-style -vet-style -warnings-as-errors -target:linux_amd64
	echo Checking linux_arm64
	odin check examples\all -vet -vet-tabs -strict-style -vet-style -warnings-as-errors -target:linux_arm64
	echo Checking linux_arm32
	odin check examples\all -vet -vet-tabs -strict-style -vet-style -warnings-as-errors -target:linux_arm32
	echo Checking linux_riscv64
	odin check examples\all -vet -vet-tabs -strict-style -vet-style -warnings-as-errors -target:linux_riscv64
	echo Checking windows_i386
	odin check examples\all -vet -vet-tabs -strict-style -vet-style -warnings-as-errors -target:windows_i386
	echo Checking windows_amd64
	odin check examples\all -vet -vet-tabs -strict-style -vet-style -warnings-as-errors -target:windows_amd64
	echo Checking freebsd_amd64
	odin check examples\all -vet -vet-tabs -strict-style -vet-style -warnings-as-errors -target:freebsd_amd64
	echo Checking freebsd_arm64
	odin check examples\all -vet -vet-tabs -strict-style -vet-style -warnings-as-errors -target:freebsd_arm64
	echo Checking netbsd_amd64
	odin check examples\all -vet -vet-tabs -strict-style -vet-style -warnings-as-errors -target:netbsd_amd64
	echo Checking netbsd_arm64
	odin check examples\all -vet -vet-tabs -strict-style -vet-style -warnings-as-errors -target:netbsd_arm64
	echo Checking openbsd_amd64
	odin check examples\all -vet -vet-tabs -strict-style -vet-style -warnings-as-errors -target:openbsd_amd64
)

if "%1" == "freestanding" (
	echo Checking freestanding_wasm32
	odin check examples\all -vet -vet-tabs -strict-style -vet-style -warnings-as-errors -target:freestanding_wasm32
	echo Checking freestanding_wasm64p32
	odin check examples\all -vet -vet-tabs -strict-style -vet-style -warnings-as-errors -target:freestanding_wasm64p32
	echo Checking freestanding_amd64_sysv
	odin check examples\all -vet -vet-tabs -strict-style -vet-style -warnings-as-errors -target:freestanding_amd64_sysv
	echo Checking freestanding_amd64_win64
	odin check examples\all -vet -vet-tabs -strict-style -vet-style -warnings-as-errors -target:freestanding_amd64_win64
	echo Checking freestanding_arm64
	odin check examples\all -vet -vet-tabs -strict-style -vet-style -warnings-as-errors -target:freestanding_arm64
	echo Checking freestanding_arm32
	odin check examples\all -vet -vet-tabs -strict-style -vet-style -warnings-as-errors -target:freestanding_arm32
	echo Checking freestanding_riscv64
	odin check examples\all -vet -vet-tabs -strict-style -vet-style -warnings-as-errors -target:freestanding_riscv64
)

if "%1" == "rare" (
	echo Checking essence_amd64
	odin check examples\all -vet -vet-tabs -strict-style -vet-style -warnings-as-errors -target:essence_amd64
	echo Checking freebsd_i386
	odin check examples\all -vet -vet-tabs -strict-style -vet-style -warnings-as-errors -target:freebsd_i386
	echo Checking haiku_amd64
	odin check examples\all -vet -vet-tabs -strict-style -vet-style -warnings-as-errors -target:haiku_amd64
)

if "%1" == "wasm" (
	echo Checking freestanding_wasm32
	odin check examples\all -vet -vet-tabs -strict-style -vet-style -warnings-as-errors -target:freestanding_wasm32
	echo Checking freestanding_wasm64p32
	odin check examples\all -vet -vet-tabs -strict-style -vet-style -warnings-as-errors -target:freestanding_wasm64p32
	echo Checking wasi_wasm64p32
	odin check examples\all -vet -vet-tabs -strict-style -vet-style -warnings-as-errors -target:wasi_wasm64p32
	echo Checking wasi_wasm32
	odin check examples\all -vet -vet-tabs -strict-style -vet-style -warnings-as-errors -target:wasi_wasm32
	echo Checking js_wasm32
	odin check examples\all -vet -vet-tabs -strict-style -vet-style -warnings-as-errors -target:js_wasm32
	echo Checking orca_wasm32
	odin check examples\all -vet -vet-tabs -strict-style -vet-style -warnings-as-errors -target:orca_wasm32
	echo Checking js_wasm64p32
	odin check examples\all -vet -vet-tabs -strict-style -vet-style -warnings-as-errors -target:js_wasm64p32
)