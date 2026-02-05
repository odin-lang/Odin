# BoringSSL (Vendored for Bifrost)

This directory vendors only the headers and static libraries needed by Bifrost.

Expected layout:
- `vendor/boringssl/include/openssl/` (public headers)
- `vendor/boringssl/lib/libssl.a`
- `vendor/boringssl/lib/libcrypto.a`

## Build Script

Use the build helper to compile BoringSSL from a sibling checkout and copy
headers/libs into this folder:

```sh
./build_boringssl.sh
```

By default the script expects the source at `../boringssl`. You can override
with `BORINGSSL_SRC=/path/to/boringssl`.

Linking:
`vendor/bifrost/tls/imports.odin` uses explicit paths to these libs, so no
extra `-L` flags are needed when the vendored libs are present.
