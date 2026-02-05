// Copyright 2014 The BoringSSL Authors
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
package bifrost_tls

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


