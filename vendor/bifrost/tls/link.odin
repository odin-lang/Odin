package bifrost_tls

// BoringSSL static libraries (vendored, Linux-only for now).
@(private) LIBSSL_PATH    :: "../../boringssl/lib/libssl.a"
@(private) LIBCRYPTO_PATH :: "../../boringssl/lib/libcrypto.a"

when !#exists(LIBSSL_PATH) {
	#panic("Could not find BoringSSL at \"" + LIBSSL_PATH + "\", build it via `" + ODIN_ROOT + "vendor/boringssl/build_boringssl.sh\"`")
}
when !#exists(LIBCRYPTO_PATH) {
	#panic("Could not find BoringSSL at \"" + LIBCRYPTO_PATH + "\", build it via `" + ODIN_ROOT + "vendor/boringssl/build_boringssl.sh\"`")
}

foreign import ssl {
	LIBSSL_PATH,
}
foreign import crypto {
	LIBCRYPTO_PATH,
}

foreign import stdcpp "system:stdc++"
