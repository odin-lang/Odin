// Copyright 1995-2016 The OpenSSL Project Authors. All Rights Reserved.
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

import "core:c"

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


@(default_calling_convention="c")
foreign lib {
	// ERR_get_error gets the packed error code for the least recent error and
	// removes that error from the queue. If there are no errors in the queue then
	// it returns zero.
	ERR_get_error :: proc() -> u32 ---

	// ERR_get_error_line acts like |ERR_get_error|, except that the file and line
	// number of the call that added the error are also returned.
	ERR_get_error_line :: proc(file: ^cstring, line: ^i32) -> u32 ---
}

// ERR_FLAG_STRING means that the |data| member is a NUL-terminated string that
// can be printed. This is always set if |data| is non-NULL.
ERR_FLAG_STRING :: 1

// ERR_FLAG_MALLOCED is passed into |ERR_set_error_data| to indicate that |data|
// was allocated with |OPENSSL_malloc|.
//
// It is, separately, returned in |*flags| from |ERR_get_error_line_data| to
// indicate that |*data| has a non-static lifetime, but this lifetime is still
// managed by the library. The caller must not call |OPENSSL_free| or |free| on
// |data|.
ERR_FLAG_MALLOCED :: 2

@(default_calling_convention="c")
foreign lib {
	// ERR_get_error_line_data acts like |ERR_get_error_line|, but also returns the
	// error-specific data pointer and flags. The flags are a bitwise-OR of
	// |ERR_FLAG_*| values. The error-specific data is owned by the error queue
	// and the pointer becomes invalid after the next call that affects the same
	// thread's error queue. If |*flags| contains |ERR_FLAG_STRING| then |*data| is
	// human-readable.
	ERR_get_error_line_data :: proc(file: ^cstring, line: ^i32, data: ^cstring, flags: ^i32) -> u32 ---

	// The "peek" functions act like the |ERR_get_error| functions, above, but they
	// do not remove the error from the queue.
	ERR_peek_error           :: proc() -> u32 ---
	ERR_peek_error_line      :: proc(file: ^cstring, line: ^i32) -> u32 ---
	ERR_peek_error_line_data :: proc(file: ^cstring, line: ^i32, data: ^cstring, flags: ^i32) -> u32 ---

	// The "peek last" functions act like the "peek" functions, above, except that
	// they return the most recent error.
	ERR_peek_last_error           :: proc() -> u32 ---
	ERR_peek_last_error_line      :: proc(file: ^cstring, line: ^i32) -> u32 ---
	ERR_peek_last_error_line_data :: proc(file: ^cstring, line: ^i32, data: ^cstring, flags: ^i32) -> u32 ---

	// ERR_error_string_n generates a human-readable string representing
	// |packed_error|, places it at |buf|, and returns |buf|. It writes at most
	// |len| bytes (including the terminating NUL) and truncates the string if
	// necessary. If |len| is greater than zero then |buf| is always NUL terminated.
	//
	// The string will have the following format:
	//
	//   error:[error code]:[library name]:OPENSSL_internal:[reason string]
	//
	// error code is an 8 digit hexadecimal number; library name and reason string
	// are ASCII text.
	ERR_error_string_n :: proc(packed_error: u32, buf: cstring, len: c.size_t) -> cstring ---

	// ERR_lib_error_string returns a string representation of the library that
	// generated |packed_error|, or a placeholder string is the library is
	// unrecognized.
	ERR_lib_error_string :: proc(packed_error: u32) -> cstring ---

	// ERR_reason_error_string returns a string representation of the reason for
	// |packed_error|, or a placeholder string if the reason is unrecognized.
	ERR_reason_error_string :: proc(packed_error: u32) -> cstring ---

	// ERR_lib_symbol_name returns the symbol name of library that generated
	// |packed_error|, or NULL if unrecognized. For example, an error from
	// |ERR_LIB_EVP| would return "EVP".
	ERR_lib_symbol_name :: proc(packed_error: u32) -> cstring ---

	// ERR_reason_symbol_name returns the symbol name of the reason for
	// |packed_error|, or NULL if unrecognized. For example, |ERR_R_INTERNAL_ERROR|
	// would return "INTERNAL_ERROR".
	//
	// Errors from the |ERR_LIB_SYS| library are typically |errno| values and will
	// return NULL. User-defined errors will also return NULL.
	ERR_reason_symbol_name :: proc(packed_error: u32) -> cstring ---
}

// ERR_print_errors_callback_t is the type of a function used by
// |ERR_print_errors_cb|. It takes a pointer to a human readable string (and
// its length) that describes an entry in the error queue. The |ctx| argument
// is an opaque pointer given to |ERR_print_errors_cb|.
//
// It should return one on success or zero on error, which will stop the
// iteration over the error queue.
ERR_print_errors_callback_t :: proc "c" (str: cstring, len: c.size_t, ctx: rawptr) -> i32

@(default_calling_convention="c")
foreign lib {
	// ERR_print_errors_cb clears the current thread's error queue, calling
	// |callback| with a string representation of each error, from the least recent
	// to the most recent error.
	//
	// The string will have the following format (which differs from
	// |ERR_error_string|):
	//
	//   [thread id]:error:[error code]:[library name]:OPENSSL_internal:[reason string]:[file]:[line number]:[optional string data]
	//
	// The callback can return one to continue the iteration or zero to stop it.
	// The |ctx| argument is an opaque value that is passed through to the
	// callback.
	ERR_print_errors_cb :: proc(callback: ERR_print_errors_callback_t, ctx: rawptr) ---

	// ERR_print_errors_fp clears the current thread's error queue, printing each
	// error to |file|. See |ERR_print_errors_cb| for the format.
	ERR_print_errors_fp :: proc(file: ^FILE) ---

	// ERR_clear_error clears the error queue for the current thread.
	ERR_clear_error :: proc() ---

	// ERR_set_mark "marks" the most recent error for use with |ERR_pop_to_mark|.
	// It returns one if an error was marked and zero if there are no errors.
	ERR_set_mark :: proc() -> i32 ---

	// ERR_pop_to_mark removes errors from the most recent to the least recent
	// until (and not including) a "marked" error. It returns zero if no marked
	// error was found (and thus all errors were removed) and one otherwise. Errors
	// are marked using |ERR_set_mark|.
	ERR_pop_to_mark :: proc() -> i32 ---

	// ERR_get_next_error_library returns a value suitable for passing as the
	// |library| argument to |ERR_put_error|. This is intended for code that wishes
	// to push its own, non-standard errors to the error queue.
	ERR_get_next_error_library :: proc() -> i32 ---
}

ERR_LIB_NONE        :: 1
ERR_LIB_RSA         :: 4
ERR_LIB_DH          :: 5
ERR_LIB_EVP         :: 6
ERR_LIB_BUF         :: 7
ERR_LIB_OBJ         :: 8
ERR_LIB_PEM         :: 9
ERR_LIB_DSA         :: 10
ERR_LIB_X509        :: 11
ERR_LIB_ASN1        :: 12
ERR_LIB_CONF        :: 13
ERR_LIB_CRYPTO      :: 14
ERR_LIB_EC          :: 15
ERR_LIB_SSL         :: 16
ERR_LIB_BIO         :: 17
ERR_LIB_PKCS7       :: 18
ERR_LIB_SYS         :: 2
ERR_LIB_BN          :: 3
ERR_LIB_PKCS8       :: 19
ERR_LIB_RAND        :: 21
ERR_LIB_OCSP        :: 23
ERR_LIB_X509V3      :: 20
ERR_LIB_COMP        :: 25
ERR_LIB_ECDSA       :: 26
ERR_LIB_ECDH        :: 27
ERR_LIB_ENGINE      :: 22
ERR_LIB_DIGEST      :: 29
ERR_LIB_CIPHER      :: 30
ERR_LIB_HKDF        :: 31
ERR_LIB_TRUST_TOKEN :: 32
ERR_LIB_CMS         :: 33
ERR_LIB_UI          :: 24
ERR_LIB_HMAC        :: 28
ERR_LIB_USER        :: 34
ERR_NUM_LIBS        :: 35

// The following reason codes used to denote an error occurring in another
// library. They are sometimes used for a stack trace.
ERR_R_SYS_LIB         :: ERR_LIB_SYS
ERR_R_BN_LIB          :: ERR_LIB_BN
ERR_R_RSA_LIB         :: ERR_LIB_RSA
ERR_R_DH_LIB          :: ERR_LIB_DH
ERR_R_EVP_LIB         :: ERR_LIB_EVP
ERR_R_BUF_LIB         :: ERR_LIB_BUF
ERR_R_OBJ_LIB         :: ERR_LIB_OBJ
ERR_R_PEM_LIB         :: ERR_LIB_PEM
ERR_R_DSA_LIB         :: ERR_LIB_DSA
ERR_R_X509_LIB        :: ERR_LIB_X509
ERR_R_ASN1_LIB        :: ERR_LIB_ASN1
ERR_R_CONF_LIB        :: ERR_LIB_CONF
ERR_R_CRYPTO_LIB      :: ERR_LIB_CRYPTO
ERR_R_EC_LIB          :: ERR_LIB_EC
ERR_R_SSL_LIB         :: ERR_LIB_SSL
ERR_R_BIO_LIB         :: ERR_LIB_BIO
ERR_R_PKCS7_LIB       :: ERR_LIB_PKCS7
ERR_R_PKCS8_LIB       :: ERR_LIB_PKCS8
ERR_R_X509V3_LIB      :: ERR_LIB_X509V3
ERR_R_RAND_LIB        :: ERR_LIB_RAND
ERR_R_ENGINE_LIB      :: ERR_LIB_ENGINE
ERR_R_OCSP_LIB        :: ERR_LIB_OCSP
ERR_R_UI_LIB          :: ERR_LIB_UI
ERR_R_COMP_LIB        :: ERR_LIB_COMP
ERR_R_ECDSA_LIB       :: ERR_LIB_ECDSA
ERR_R_ECDH_LIB        :: ERR_LIB_ECDH
ERR_R_CMS_LIB         :: ERR_LIB_CMS
ERR_R_HMAC_LIB        :: ERR_LIB_HMAC
ERR_R_USER_LIB        :: ERR_LIB_USER
ERR_R_DIGEST_LIB      :: ERR_LIB_DIGEST
ERR_R_CIPHER_LIB      :: ERR_LIB_CIPHER
ERR_R_HKDF_LIB        :: ERR_LIB_HKDF
ERR_R_TRUST_TOKEN_LIB :: ERR_LIB_TRUST_TOKEN

// The following values are global reason codes. They may occur in any library.
ERR_R_FATAL                       :: 64
ERR_R_MALLOC_FAILURE              :: (1|ERR_R_FATAL)
ERR_R_SHOULD_NOT_HAVE_BEEN_CALLED :: (2|ERR_R_FATAL)
ERR_R_PASSED_NULL_PARAMETER       :: (3|ERR_R_FATAL)
ERR_R_INTERNAL_ERROR              :: (4|ERR_R_FATAL)
ERR_R_OVERFLOW                    :: (5|ERR_R_FATAL)

@(default_calling_convention="c")
foreign lib {
	// ERR_load_BIO_strings does nothing.
	ERR_load_BIO_strings :: proc() ---

	// ERR_load_ERR_strings does nothing.
	ERR_load_ERR_strings :: proc() ---

	// ERR_load_crypto_strings does nothing.
	ERR_load_crypto_strings :: proc() ---

	// ERR_load_RAND_strings does nothing.
	ERR_load_RAND_strings :: proc() ---

	// ERR_free_strings does nothing.
	ERR_free_strings :: proc() ---

	// ERR_remove_state calls |ERR_clear_error|.
	ERR_remove_state :: proc(pid: c.ulong) ---

	// ERR_remove_thread_state clears the error queue for the current thread if
	// |tid| is NULL. Otherwise it calls |assert(0)|, because it's no longer
	// possible to delete the error queue for other threads.
	//
	// Use |ERR_clear_error| instead. Note error queues are deleted automatically on
	// thread exit. You do not need to call this function to release memory.
	ERR_remove_thread_state :: proc(tid: ^CRYPTO_THREADID) ---

	// ERR_func_error_string returns the string "OPENSSL_internal".
	ERR_func_error_string :: proc(packed_error: u32) -> cstring ---

	// ERR_error_string behaves like |ERR_error_string_n| but |len| is implicitly
	// |ERR_ERROR_STRING_BUF_LEN|.
	//
	// Additionally, if |buf| is NULL, the error string is placed in a static buffer
	// which is returned. This is not thread-safe and only exists for backwards
	// compatibility with legacy callers. The static buffer will be overridden by
	// calls in other threads.
	//
	// Use |ERR_error_string_n| instead.
	//
	// TODO(fork): remove this function.
	ERR_error_string :: proc(packed_error: u32, buf: cstring) -> cstring ---
}

ERR_ERROR_STRING_BUF_LEN :: 120

// ERR_TXT_* are provided for compatibility with code that assumes that it's
// using OpenSSL.
ERR_TXT_STRING   :: ERR_FLAG_STRING
ERR_TXT_MALLOCED :: ERR_FLAG_MALLOCED

@(default_calling_convention="c")
foreign lib {
	// ERR_clear_system_error clears the system's error value (i.e. errno).
	ERR_clear_system_error :: proc() ---

	// ERR_put_error adds an error to the error queue, dropping the least recent
	// error if necessary for space reasons.
	ERR_put_error :: proc(library: i32, unused: i32, reason: i32, file: cstring, line: u32) ---

	// ERR_add_error_data takes a variable number (|count|) of const char*
	// pointers, concatenates them and sets the result as the data on the most
	// recent error.
	ERR_add_error_data :: proc(count: u32, #c_vararg _: ..any) ---

	// ERR_add_error_dataf takes a printf-style format and arguments, and sets the
	// result as the data on the most recent error.
	ERR_add_error_dataf :: proc(format: cstring, #c_vararg _: ..any) ---

	// ERR_set_error_data sets the data on the most recent error to |data|, which
	// must be a NUL-terminated string. |flags| must contain |ERR_FLAG_STRING|. If
	// |flags| contains |ERR_FLAG_MALLOCED|, this function takes ownership of
	// |data|, which must have been allocated with |OPENSSL_malloc|. Otherwise, it
	// saves a copy of |data|.
	//
	// Note this differs from OpenSSL which, when |ERR_FLAG_MALLOCED| is unset,
	// saves the pointer as-is and requires it remain valid for the lifetime of the
	// address space.
	ERR_set_error_data :: proc(data: cstring, flags: i32) ---
}

// ERR_NUM_ERRORS is one more than the limit of the number of errors in the
// queue.
ERR_NUM_ERRORS :: 16

