package darwin_system_dylib

foreign import z "system:libz.dylib"

foreign z {
	zlibVersion :: proc "c" () -> cstring ---
}

main :: proc() {
	assert(zlibVersion() != nil)
}
