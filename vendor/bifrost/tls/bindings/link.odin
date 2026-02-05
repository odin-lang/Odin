package bifrost_tls_bindings

// Link BoringSSL static libs and the C++ runtime for the bindings package.
foreign import lib {
	LIBSSL_PATH,
	LIBCRYPTO_PATH,
	"system:stdc++",
	"system:gcc_s",
}
