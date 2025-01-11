package curl

// SSL_Verify specifies the verification level for SSL/TLS connections.
SSL_Verify :: enum {
  // Disable all verification (INSECURE)
  None = 0,

  // Verify hostname against certificate
  Host = 1,

  // Verify certificate authenticity
  Peer = 2,

  // Verify both hostname and certificate (recommended)
  Both = 3,
}

// SSL_Config provides configuration options for HTTPS connections.
SSL_Config :: struct {
  // Path to CA (Certificate Authority) bundle file for peer verification
  ca_file: string,

  // Path to directory containing CA certificates
  ca_path: string,

  // Client certificate file path for client authentication
  client_cert: string,

  // Private key file for client certificate
  client_key: string,

  // Password for the private key file
  key_password: string,

  // TLS protocol version to use, nil uses curl's default
  version: Maybe(SSL_Version),

  // List of allowed cipher suites, empty uses system default
  cipher_list: string,

  // Enable certificate status checking via OCSP
  verify_status: bool,

  // Name of crypto engine to use for SSL operations
  engine: string,
}

// SSL_Version specifies the SSL/TLS protocol version to use.
SSL_Version :: enum u32 {
  // Use default protocol negotiation
  Default = CURL_SSLVERSION_DEFAULT,

  // TLS 1.x (any TLS version 1)
  TLS_1 = CURL_SSLVERSION_TLSv1,

  // TLS 1.0
  TLS_1_0 = CURL_SSLVERSION_TLSv1_0,

  // TLS 1.1
  TLS_1_1 = CURL_SSLVERSION_TLSv1_1,

  // TLS 1.2
  TLS_1_2 = CURL_SSLVERSION_TLSv1_2,

  // TLS 1.3
  TLS_1_3 = CURL_SSLVERSION_TLSv1_3,
}

// Protocol version constants used with SSL_Version
CURL_SSLVERSION_DEFAULT :: 0
CURL_SSLVERSION_TLSv1   :: 1 // TLS 1.x
CURL_SSLVERSION_TLSv1_0 :: 4
CURL_SSLVERSION_TLSv1_1 :: 5
CURL_SSLVERSION_TLSv1_2 :: 6
CURL_SSLVERSION_TLSv1_3 :: 7
