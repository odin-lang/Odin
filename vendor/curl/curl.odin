// Package curl implements minimal bindings to libcurl.
//
// This implementation is based on curl.h version 8.11.1:
// [[ More; https://github.com/curl/curl/blob/curl-8_11_1/include/curl/curl.h ]]
package curl

import "base:runtime"
import "core:c"
import "core:strings"

// CURL represents an easy handle.
//
// **Note**: An easy handle can perform one transfer at a time but can be reused
// for multiple transfers.
CURL :: distinct rawptr

// CURL_GLOBAL_ALL combines all initialization flags.
CURL_GLOBAL_ALL: i64 = 3

// CURLOPT represents options for a transfer.
CURLOPT :: enum i32 {
  // Basic options
  WRITEFUNCTION  = 20011, // Callback for receiving data
  WRITEDATA      = 10001, // Data pointer passed to write callback
  URL            = 10002, // URL to request
  USERAGENT      = 10018, // User-Agent header
  HTTPHEADER     = 10023, // Custom HTTP headers
  POST           = 47,    // Enable POST
  POSTFIELDS     = 10015, // POST data
  VERBOSE        = 41,    // Enable verbose output
  TIMEOUT_MS     = 155,   // Timeout in milliseconds
  FOLLOWLOCATION = 52,    // Follow redirects
  MAXREDIRS      = 68,    // Maximum redirects to follow

  // SSL/TLS options
  SSL_VERIFYPEER    = 64,    // Verify the peer (0 or 1)
  SSL_VERIFYHOST    = 81,    // Host verification level (0, 1, or 2)
  SSL_VERIFYSTATUS  = 232,   // Check certificate status
  SSLVERSION        = 32,    // SSL protocol version
  SSL_CIPHER_LIST   = 10083, // Allowed ciphers

  // SSL certificate options
  CAINFO            = 10065, // Path to CA bundle file
  CAPATH            = 10097, // Directory of CA certificates
  SSLCERT           = 10025, // Client certificate path
  SSLKEY            = 10087, // Private key file path
  KEYPASSWD         = 10026, // Private key password

  // SSL engine options
  SSLENGINE         = 10089, // Crypto engine to use
  SSLENGINE_DEFAULT = 90,    // Set default crypto engine
}

// CURLINFO represents information retrieval options.
CURLINFO :: enum i32 {
  // Response status code
  Response_Code = 0x200000 + 2,
}

// Error represents libcurl error codes.
//
// This maps directly to CURLcode error values from curl.h.
Error :: enum {
  None                    = 0,  // CURLE_OK
  Unsupported_Protocol    = 1,  // CURLE_UNSUPPORTED_PROTOCOL
  Failed_Init             = 2,  // CURLE_FAILED_INIT
  URL_Malformat           = 3,  // CURLE_URL_MALFORMAT
  Not_Built_In            = 4,  // CURLE_NOT_BUILT_IN
  Couldnt_Resolve_Proxy   = 5,  // CURLE_COULDNT_RESOLVE_PROXY
  Couldnt_Resolve_Host    = 6,  // CURLE_COULDNT_RESOLVE_HOST
  Couldnt_Connect         = 7,  // CURLE_COULDNT_CONNECT
  Remote_Access_Denied    = 9,  // CURLE_REMOTE_ACCESS_DENIED
  HTTP_Returned_Error     = 22, // CURLE_HTTP_RETURNED_ERROR
  Write_Error             = 23, // CURLE_WRITE_ERROR
  Upload_Failed           = 25, // CURLE_UPLOAD_FAILED
  Read_Error              = 26, // CURLE_READ_ERROR
  Out_Of_Memory           = 27, // CURLE_OUT_OF_MEMORY
  Operation_Timedout      = 28, // CURLE_OPERATION_TIMEDOUT
  SSL_Connect_Error       = 35, // CURLE_SSL_CONNECT_ERROR
  Bad_Download_Resume     = 36, // CURLE_BAD_DOWNLOAD_RESUME
  Too_Many_Redirects      = 47, // CURLE_TOO_MANY_REDIRECTS
  Got_Nothing             = 52, // CURLE_GOT_NOTHING
  SSL_Engine_Not_Found    = 53, // CURLE_SSL_ENGINE_NOTFOUND
  SSL_Engine_Set_Failed   = 54, // CURLE_SSL_ENGINE_SETFAILED
  Send_Error              = 55, // CURLE_SEND_ERROR
  Recv_Error              = 56, // CURLE_RECV_ERROR
  SSL_Cert_Problem        = 58, // CURLE_SSL_CERTPROBLEM
  SSL_Cipher              = 59, // CURLE_SSL_CIPHER
  Peer_Failed_Verify      = 60, // CURLE_PEER_FAILED_VERIFICATION
  Bad_Content_Encoding    = 61, // CURLE_BAD_CONTENT_ENCODING
  SSL_Engine_Init_Failed  = 66, // CURLE_SSL_ENGINE_INITFAILED
  SSL_CRL_Bad_File        = 82, // CURLE_SSL_CRL_BADFILE
  SSL_Issuer_Error        = 83, // CURLE_SSL_ISSUER_ERROR
  SSL_Invalid_Cert_Status = 91, // CURLE_SSL_INVALIDCERTSTATUS
  SSL_Client_Cert         = 98, // CURLE_SSL_CLIENTCERT
}

// Slist represents a linked list of strings used by curl.
Slist :: struct {
  // String data in this node
  data: cstring,

  // Pointer to next node
  next: ^Slist,
}

// Context holds an easy handle and its configuration state.
//
// **Note**: The context must be destroyed with destroy_context when no longer needed.
Context :: struct {
  // The curl easy handle
  curl: CURL,

  // List of HTTP headers
  headers: ^Slist,

  // Memory allocator
  allocator: runtime.Allocator,
}

// Write_Callback represents a callback for handling received data.
//
// Inputs:
// - data: Buffer containing received data
// - size: Size of each data unit
// - nmemb: Number of data units
// - userdata: User provided data pointer
//
// Returns: Number of bytes handled.
Write_Callback :: #type proc "c" (data: rawptr, size: c.size_t, nmemb: c.size_t, userdata: rawptr) -> c.size_t

// Import the appropriate libcurl library based on OS
when ODIN_OS == .Windows {
  foreign import lib "system:libcurl.dll"
} else when ODIN_OS == .Linux {
  foreign import lib "system:libcurl.so"
} else when ODIN_OS == .Darwin {
  foreign import lib "system:libcurl.dylib"
}

@(default_calling_convention="c")
foreign lib {
  // Initialize the curl library.
  //
  // Returns: Error.None on success.
  //
  // [[ More; https://curl.se/libcurl/c/curl_global_init.html ]]
  curl_global_init :: proc(flags: c.long) -> i32 ---

  // Cleanup the curl library.
  //
  // [[ More; https://curl.se/libcurl/c/curl_global_cleanup.html ]]
  curl_global_cleanup :: proc() ---

  // Create an easy handle.
  //
  // Returns: A new easy handle on success, nil on failure.
  //
  // [[ More; https://curl.se/libcurl/c/curl_easy_init.html ]]
  curl_easy_init :: proc() -> CURL ---

  // Clean up and destroy an easy handle.
  //
  // [[ More; https://curl.se/libcurl/c/curl_easy_cleanup.html ]]
  curl_easy_cleanup :: proc(handle: CURL) ---

  // Set transfer options.
  //
  // Returns: Error.None on success.
  //
  // [[ More; https://curl.se/libcurl/c/curl_easy_setopt.html ]]
  curl_easy_setopt :: proc(handle: CURL, option: CURLOPT, #c_vararg args: ..any) -> i32 ---

  // Perform a transfer.
  //
  // Returns: Error.None on success.
  //
  // [[ More; https://curl.se/libcurl/c/curl_easy_perform.html ]]
  curl_easy_perform :: proc(handle: CURL) -> i32 ---

  // Get transfer information.
  //
  // Returns: Error.None on success.
  //
  // [[ More; https://curl.se/libcurl/c/curl_easy_getinfo.html ]]
  curl_easy_getinfo :: proc(handle: CURL, info: CURLINFO, #c_vararg args: ..any) -> i32 ---

  // Get string description of error code.
  //
  // Returns: A null-terminated string describing the error code.
  //
  // [[ More; https://curl.se/libcurl/c/curl_easy_strerror.html ]]
  curl_easy_strerror :: proc(code: i32) -> cstring ---

  // Add a string to an Slist.
  //
  // Returns: The new list on success, nil on failure.
  //
  // [[ More; https://curl.se/libcurl/c/curl_slist_append.html ]]
  curl_slist_append :: proc(list: ^Slist, str: cstring) -> ^Slist ---

  // Free an entire Slist.
  //
  // [[ More; https://curl.se/libcurl/c/curl_slist_free_all.html ]]
  curl_slist_free_all :: proc(list: ^Slist) ---
}

// Initialize curl library.
//
// **Note**: cleanup must be called when done using the library.
//
// Returns: true on success, false on failure.
init :: proc() -> (ok: bool) {
  return curl_global_init(CURL_GLOBAL_ALL) == 0
}

// Cleanup curl library.
cleanup :: proc() {
  curl_global_cleanup()
}

// Create new transfer context.
//
// Inputs:
// - allocator: Memory allocator to use
//
// Returns:
// - ctx: New context
// - err: Error state
init_context :: proc(allocator := context.allocator) -> (ctx: ^Context, err: Error) {
  curl := curl_easy_init()
  if curl == nil {
    return nil, .Failed_Init
  }

  ctx = new(Context, allocator)
  ctx.curl = curl
  ctx.allocator = allocator
  return ctx, .None
}

// Destroy context and free its resources.
//
// Inputs:
// - ctx: Context to destroy
destroy_context :: proc(ctx: ^Context) {
  if ctx == nil do return

  if ctx.headers != nil {
    curl_slist_free_all(ctx.headers)
  }
  curl_easy_cleanup(ctx.curl)
  free(ctx, ctx.allocator)
}

// Add HTTP header to context.
//
// Inputs:
// - ctx: Context to add header to
// - header: Header string to add
//
// Returns: true on success, false on failure.
add_header :: proc(ctx: ^Context, header: string) -> bool {
  if ctx == nil do return false

  cstr := strings.clone_to_cstring(header, context.temp_allocator)
  new_headers := curl_slist_append(ctx.headers, cstr)
  if new_headers == nil do return false

  ctx.headers = new_headers
  return set_opt(ctx, .HTTPHEADER, ctx.headers)
}

// Perform a transfer.
//
// Inputs:
// - ctx: Context to perform transfer with
//
// Returns: Error state.
perform :: proc(ctx: ^Context) -> Error {
  if ctx == nil do return .Out_Of_Memory

  result := curl_easy_perform(ctx.curl)
  if result != 0 {
    return curl_code_to_error(result)
  }
  return .None
}

// Returns human-readable description of a curl error.
//
// Inputs:
// - err: Error to describe
//
// Returns: Human-readable error message.
error_string :: proc(err: Error) -> string {
  return string(curl_easy_strerror(i32(err)))
}

// Convert curl error code to Error enum.
//
// Inputs:
// - code: Raw curl error code
//
// Returns: Mapped Error value.
@(private)
curl_code_to_error :: proc(code: i32) -> Error {
  return Error(code)
}

// Set transfer option on context.
//
// Inputs:
// - ctx: Context to set option on
// - option: Option to set
// - value: Value for the option
//
// Returns: true if option was set successfully.
@(private)
set_opt :: proc(ctx: ^Context, option: CURLOPT, value: $T) -> (ok: bool) {
  if ctx == nil do return false

  result: i32
  when T == string {
    cstr := strings.clone_to_cstring(value, context.temp_allocator)
    result = curl_easy_setopt(ctx.curl, option, cstr)
  } else when T == Write_Callback {
    result = curl_easy_setopt(ctx.curl, option, value)
  } else when T == bool {
    val := c.long(0)
    if value do val = 1
    result = curl_easy_setopt(ctx.curl, option, val)
  } else when T == ^Slist {
    result = curl_easy_setopt(ctx.curl, option, value)
  } else {
    result = curl_easy_setopt(ctx.curl, option, value)
  }

  if result != 0 {
    return false
  }

  return true
}

// Get information about a completed transfer.
//
// Inputs:
// - ctx: Context to get info from
// - info: Type of information to get
//
// Returns:
// - status: Information value
// - ok: true if info was retrieved successfully
@(private)
get_info :: proc(ctx: ^Context, info: CURLINFO) -> (status: c.long, ok: bool) {
  if ctx == nil do return 0, false

  result := curl_easy_getinfo(ctx.curl, info, &status)

  return status, result == 0
}
