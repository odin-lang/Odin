package curl

import "base:runtime"
import "base:intrinsics"
import "core:c"
import "core:bytes"
import "core:strings"
import "core:time"

@(require) import "core:encoding/json"
@(require) import "core:reflect"

// Parser_Type describes how response data was parsed and how it should be cleaned up.
Parser_Type :: enum {
  // Raw byte data - no parsing was performed
  None,

  // Data was parsed as a string using string_parser
  String,

  // Data was parsed as JSON using json_parser
  JSON,

  // Data was parsed using a custom parser
  Custom,
}

// Response represents an HTTP response with a typed body.
Response :: struct($Body_Type: typeid) {
  // HTTP response status code
  status_code: int,

  // Response body of type Body_Type
  body: Body_Type,

  // Error state if any
  error: Error,

  // Memory allocator used for response data
  allocator: runtime.Allocator,

  // How the response was parsed
  parser_type: Parser_Type,
}

// Request_Config represents HTTP request configuration options.
Request_Config :: struct {
  // Custom HTTP headers to add to the request
  headers: []string,

  // Enable verbose output for debugging
  verbose: bool,

  // Duration before request times out (0 means no timeout)
  timeout: time.Duration,

  // Follow HTTP redirects (3xx responses)
  follow_location: bool,

  // Maximum number of redirects to follow (0 means unlimited)
  max_redirects: uint,

  // Memory allocator to use for request data
  allocator: runtime.Allocator,

  // SSL verification level for HTTPS connections
  // .Both (default) verifies both certificate and hostname
  // .Peer verifies only the certificate
  // .Host verifies only the hostname
  // .None disables all verification (INSECURE)
  ssl_verify: SSL_Verify,

  // Advanced SSL/TLS options including client certificates,
  // custom CA certificates, and protocol settings.
  // When nil, uses system's default secure settings.
  ssl: ^SSL_Config,
}

// Raw_Response represents the base HTTP response result before parsing.
Raw_Response :: struct {
  // HTTP response status code
  status_code: int,

  // Raw response body bytes
  body: []byte,

  // Error state if any
  error: Error,

  // Memory allocator used for response data
  allocator: runtime.Allocator,
}

// Method represents supported HTTP methods.
Method :: enum {
  Get,
  Post,
}

// Request_Options encapsulates all configuration for an HTTP request.
Request_Options :: struct {
  // Base configuration including headers, timeouts, etc.
  config: Request_Config,

  // HTTP method to use
  method: Method,

  // Data to send in request body
  data: string,
}

// Parser describes how to convert raw response bytes to a desired type.
Parser :: struct($T: typeid) {
  // Parsing function that converts bytes to type T
  parse: proc(data: []byte, allocator: runtime.Allocator, err: ^Error) -> T,
}

// write_callback handles received data from curl.
//
// Inputs:
// - data: Buffer containing received data
// - size: Size of each data unit
// - nmemb: Number of data units
// - user_data: User provided data pointer
//
// Returns: Number of bytes handled.
write_callback :: proc "c" (data: rawptr, size: c.size_t, nmemb: c.size_t, user_data: rawptr) -> c.size_t {
  if data == nil || user_data == nil do return 0
  context = runtime.default_context()

  buf := (^bytes.Buffer)(user_data)
  bytes_data := ([^]byte)(data)[:size * nmemb]
  bytes.buffer_write(buf, bytes_data)
  return size * nmemb
}

// destroy_response frees resources associated with a response based on its parser type.
//
// Inputs:
// - res: Response to destroy
destroy_response :: proc(res: ^Response($T)) {
  if res == nil do return

  switch res.parser_type {
  case .None:
    when intrinsics.type_is_slice(T) {
      if len(res.body) > 0 {
        delete(res.body, res.allocator)
      }
    }
  case .String:
    when intrinsics.type_is_string(T) {
      if len(res.body) > 0 {
        delete(res.body, res.allocator)
      }
    }
  case .JSON:
    fields := reflect.struct_fields_zipped(typeid_of(T))
    for field in fields {
      if reflect.is_string(field.type) {
        str := (^string)(rawptr(uintptr(&res.body) + field.offset))^
          if len(str) > 0 {
            delete(str, res.allocator)
          }
      }
    }
  case .Custom:
    // Custom types must handle their own cleanup in the caller's scope
  }
}

// do_request performs the actual HTTP request with the given configuration.
//
// Inputs:
// - url: Target URL to request
// - opts: Request options including method, config and data
//
// Returns: Raw response containing status code, body bytes and any error state.
@(private)
do_request :: proc(url: string, opts: Request_Options) -> Raw_Response {
  allocator := opts.config.allocator if opts.config.allocator.procedure != nil else context.allocator

  ctx, init_err := init_context(allocator)
  if init_err != .None {
    return Raw_Response{error = init_err, allocator = allocator}
  }
  defer destroy_context(ctx)

  buf: bytes.Buffer
  bytes.buffer_init_allocator(&buf, 0, 0, allocator)
  defer bytes.buffer_destroy(&buf)

  // Common options
  if !set_opt(ctx, .URL, url) ||
    !set_opt(ctx, .WRITEFUNCTION, write_callback) ||
    !set_opt(ctx, .WRITEDATA, &buf) {
      return Raw_Response{error = .Failed_Init, allocator = allocator}
    }

  // Set SSL options if HTTPS
  if strings.has_prefix(url, "https://") {
    if !set_opt(ctx, .SSL_VERIFYPEER, i32(opts.config.ssl_verify >= .Peer)) {
      return Raw_Response{error = .Failed_Init, allocator = allocator}
    }
    if !set_opt(ctx, .SSL_VERIFYHOST, i32(opts.config.ssl_verify >= .Host) * 2) {
      return Raw_Response{error = .Failed_Init, allocator = allocator}
    }

    if opts.config.ssl != nil {
      ssl := opts.config.ssl

      if len(ssl.ca_file) > 0 {
        if !set_opt(ctx, .CAINFO, ssl.ca_file) {
          return Raw_Response{error = .Failed_Init, allocator = allocator}
        }
      }
      if len(ssl.ca_path) > 0 {
        if !set_opt(ctx, .CAPATH, ssl.ca_path) {
          return Raw_Response{error = .Failed_Init, allocator = allocator}
        }
      }
      if len(ssl.client_cert) > 0 {
        if !set_opt(ctx, .SSLCERT, ssl.client_cert) {
          return Raw_Response{error = .Failed_Init, allocator = allocator}
        }
      }
      if len(ssl.client_key) > 0 {
        if !set_opt(ctx, .SSLKEY, ssl.client_key) {
          return Raw_Response{error = .Failed_Init, allocator = allocator}
        }
      }
      if len(ssl.key_password) > 0 {
        if !set_opt(ctx, .KEYPASSWD, ssl.key_password) {
          return Raw_Response{error = .Failed_Init, allocator = allocator}
        }
      }
      if ssl.version != nil {
        if !set_opt(ctx, .SSLVERSION, u32(ssl.version.?)) {
          return Raw_Response{error = .Failed_Init, allocator = allocator}
        }
      }
      if len(ssl.cipher_list) > 0 {
        if !set_opt(ctx, .SSL_CIPHER_LIST, ssl.cipher_list) {
          return Raw_Response{error = .Failed_Init, allocator = allocator}
        }
      }
      if ssl.verify_status {
        if !set_opt(ctx, .SSL_VERIFYSTATUS, ssl.verify_status) {
          return Raw_Response{error = .Failed_Init, allocator = allocator}
        }
      }
      if len(ssl.engine) > 0 {
        if !set_opt(ctx, .SSLENGINE, ssl.engine) {
          return Raw_Response{error = .Failed_Init, allocator = allocator}
        }
        if !set_opt(ctx, .SSLENGINE_DEFAULT, 1) {
          return Raw_Response{error = .Failed_Init, allocator = allocator}
        }
      }
    }
  }

  // Method specific setup
  switch opts.method {
  case .Post:
    if !set_opt(ctx, .POST, true) ||
      !set_opt(ctx, .POSTFIELDS, opts.data) {
        return Raw_Response{error = .Failed_Init, allocator = allocator}
      }
  case .Get:
    // GET is default, no extra setup needed
  }

  // Configure common options
  if opts.config.verbose {
    set_opt(ctx, .VERBOSE, true)
  }

  if opts.config.timeout > 0 {
    ms := time.duration_milliseconds(opts.config.timeout)
    if !set_opt(ctx, .TIMEOUT_MS, c.long(ms)) {
      return Raw_Response{error = .Failed_Init, allocator = allocator}
    }
  }

  if opts.config.follow_location {
    if !set_opt(ctx, .FOLLOWLOCATION, opts.config.follow_location) {
      return Raw_Response{error = .Failed_Init, allocator = allocator}
    }
    if opts.config.max_redirects > 0 {
      if !set_opt(ctx, .MAXREDIRS, c.long(opts.config.max_redirects)) {
        return Raw_Response{error = .Failed_Init, allocator = allocator}
      }
    }
  }

  // Set custom headers
  for header in opts.config.headers {
    if !add_header(ctx, header) {
      return Raw_Response{error = .Failed_Init, allocator = allocator}
    }
  }

  // Perform request
  if err := perform(ctx); err != .None {
    return Raw_Response{error = err, allocator = allocator}
  }

  // Get response status
  status, ok := get_info(ctx, .Response_Code)
  if !ok {
    return Raw_Response{error = .Got_Nothing, allocator = allocator}
  }

  data := bytes.buffer_to_bytes(&buf)
  if len(data) == 0 {
    return Raw_Response{
      status_code = int(status),
      allocator = allocator,
    }
  }

  response_data := make([]byte, len(data), allocator)
  copy(response_data, data)

  return Raw_Response{
    status_code = int(status),
    body = response_data,
    allocator = allocator,
  }
}

// do_method performs the internal request with specified HTTP method and returns raw bytes.
//
// **Note**: The returned Response bytes must be freed with destroy_response.
//
// Inputs:
// - method: HTTP method to use for the request
// - url: Target URL to request
// - data: Data to send in request body (if applicable)
// - config: Optional request configuration
//
// Returns: Response containing raw bytes.
@(private)
do_method :: proc(method: Method, url: string, data: string = "", config := Request_Config{}) -> Response([]byte) {
  raw_res := do_request(url, Request_Options{
    config = config,
    method = method,
    data = data,
  })
  return Response([]byte){
    status_code = raw_res.status_code,
    body = raw_res.body,
    error = raw_res.error,
    allocator = raw_res.allocator,
    parser_type = .None,
  }
}

// do_method_with performs the internal request with specified HTTP method and parses the response.
//
// **Note**: The returned Response must be freed with destroy_response. Memory management
// for custom parsers must be handled by the Parser implementation.
//
// Inputs:
// - method: HTTP method to use for the request
// - T: Type to parse response into
// - url: Target URL to request
// - data: Data to send in request body (if applicable)
// - parser: Parser to convert response bytes to type T
// - config: Optional request configuration
//
// Returns: Response containing parsed body of type T.
@(private)
do_method_with :: proc(method: Method, $T: typeid, url: string, data: string, parser: Parser(T), config := Request_Config{}) -> Response(T) {
  raw_res := do_method(method, url, data, config)
  if raw_res.error != .None {
    return Response(T){error = raw_res.error, allocator = raw_res.allocator}
  }
  defer if raw_res.body != nil {
    delete(raw_res.body, raw_res.allocator)
  }

  err: Error
  parsed_body := parser.parse(raw_res.body, raw_res.allocator, &err)
  if err != .None {
    return Response(T){error = err, allocator = raw_res.allocator}
  }

  return Response(T){
    status_code = raw_res.status_code,
    body = parsed_body,
    error = .None,
    allocator = raw_res.allocator,
    parser_type = .Custom,
  }
}

// string_parser provides built-in string parsing.
//
// Inputs:
// - data: Raw response bytes to parse
// - allocator: Memory allocator to use
// - err: Error state if parsing fails
//
// Returns: Parsed string value.
string_parser :: Parser(string){
  parse = proc(data: []byte, allocator: runtime.Allocator, err: ^Error) -> string {
    if len(data) == 0 do return ""
    return strings.clone(string(data), allocator)
  },
}

// json_parser provides built-in JSON parsing.
//
// Inputs:
// - T: Target type to unmarshal JSON into
//
// Returns: Parser configured for JSON parsing.
json_parser :: proc($T: typeid) -> Parser(T) {
  return Parser(T){
    parse = proc(data: []byte, allocator: runtime.Allocator, err: ^Error) -> T {
      val, parse_err := json.parse(data, allocator=allocator)
      if parse_err != nil {
        err^ = .Bad_Content_Encoding
        return T{}
      }
      defer json.destroy_value(val)

      target: T
      if unmarshal_err := json.unmarshal(data, &target, allocator=allocator); unmarshal_err != nil {
        err^ = .Bad_Content_Encoding
        return T{}
      }
      return target
    },
  }
}

// get performs a GET request returning raw bytes.
//
// **Note**: The returned Response must be freed with destroy_response.
//
// Inputs:
// - url: Target URL to request
// - config: Optional request configuration
//
// Returns: Response containing raw bytes.
get :: proc(url: string, config := Request_Config{}) -> Response([]byte) {
  return do_method(.Get, url, "", config)
}

// get_with performs a GET request with custom response parsing.
//
// **Note**: The returned Response must be freed with destroy_response.
//
// Inputs:
// - T: Target type to parse response into
// - url: Target URL to request
// - parser: Parser to convert response bytes to type T
// - config: Optional request configuration
//
// Returns: Response containing parsed body of type T.
get_with :: proc($T: typeid, url: string, parser: Parser(T), config := Request_Config{}) -> Response(T) {
  return do_method_with(.Get, T, url, "", parser, config)
}

// get_string performs a GET request returning a string response.
//
// **Note**: The returned Response must be freed with destroy_response.
//
// Inputs:
// - url: Target URL to request
// - config: Optional request configuration
//
// Returns: Response containing string body.
get_string :: proc(url: string, config := Request_Config{}) -> Response(string) {
  res := get_with(string, url, string_parser, config)
  res.parser_type = .String
  return res
}

// get_json performs a GET request with JSON response.
//
// **Note**: The returned Response must be freed with destroy_response.
//
// Inputs:
// - T: Target struct type to unmarshal JSON into
// - url: Target URL to request
// - config: Optional request configuration
//
// Returns: Response containing unmarshaled JSON body as type T.
get_json :: proc($T: typeid, url: string, config := Request_Config{}) -> Response(T) {
  res := get_with(T, url, json_parser(T), config)
  res.parser_type = .JSON
  return res
}

// post performs a POST request returning raw bytes.
//
// **Note**: The returned Response must be freed with destroy_response.
//
// Inputs:
// - url: Target URL to request
// - data: Data to send in request body
// - config: Optional request configuration
//
// Returns: Response containing raw bytes.
post :: proc(url: string, data: string, config := Request_Config{}) -> Response([]byte) {
  return do_method(.Post, url, data, config)
}

// post_with performs a POST request with custom response parsing.
//
// **Note**: The returned Response must be freed with destroy_response.
//
// Inputs:
// - T: Target type to parse response into
// - url: Target URL to request
// - data: Data to send in request body
// - parser: Parser to convert response bytes to type T
// - config: Optional request configuration
//
// Returns: Response containing parsed body of type T.
post_with :: proc($T: typeid, url: string, data: string, parser: Parser(T), config := Request_Config{}) -> Response(T) {
  return do_method_with(.Post, T, url, data, parser, config)
}

// post_string performs a POST request returning a string response.
//
// **Note**: The returned Response must be freed with destroy_response.
//
// Inputs:
// - url: Target URL to request
// - data: Data to send in request body
// - config: Optional request configuration
//
// Returns: Response containing string body.
post_string :: proc(url: string, data: string, config := Request_Config{}) -> Response(string) {
  res := post_with(string, url, data, string_parser, config)
  res.parser_type = .String
  return res
}

// post_json performs a POST request with JSON response.
//
// **Note**: The returned Response must be freed with destroy_response.
//
// Inputs:
// - T: Target struct type to unmarshal JSON into
// - url: Target URL to request
// - data: JSON data to send in request body
// - config: Optional request configuration
//
// Returns: Response containing unmarshaled JSON body as type T.
post_json :: proc($T: typeid, url: string, data: string, config := Request_Config{}) -> Response(T) {
  res := post_with(T, url, data, json_parser(T), config)
  res.parser_type = .JSON
  return res
}
