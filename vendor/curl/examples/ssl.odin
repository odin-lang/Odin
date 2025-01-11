package examples

import "core:fmt"
import curl "../"

main :: proc() {
  if !curl.init() {
    fmt.eprintln("Failed to initialize curl")
    return
  }
  defer curl.cleanup()

  fmt.println("\n# Basic HTTPS with default settings")
  {
    res := curl.get("https://httpbin.org/get")
    defer curl.destroy_response(&res)

    if res.error != .None {
      fmt.eprintln("Request failed:", curl.error_string(res.error))
      return
    }
    fmt.println("Success:", string(res.body))
  }

  fmt.println("\n# Force specific TLS version")
  {
    config := curl.Request_Config{
      ssl_verify = .Both,
      ssl = &curl.SSL_Config{
        version = .TLS_1_2,
      },
    }

    res := curl.get("https://httpbin.org/get", config)
    defer curl.destroy_response(&res)

    if res.error != .None {
      fmt.eprintln("Request failed:", curl.error_string(res.error))
      return
    }
    fmt.println("Success with TLS 1.2:", string(res.body))
  }

  fmt.println("\n# Testing SSL error handling with badssl.com")
  {
    config := curl.Request_Config{
      ssl_verify = .Both,
    }

    res := curl.get("https://expired.badssl.com", config)
    defer curl.destroy_response(&res)

    if res.error == .Peer_Failed_Verify {
      fmt.println("Successfully detected expired certificate")
    } else {
      fmt.println("Unexpected result:", res.error)
    }
  }

  /* Example configuration for client certificate authentication
  fmt.println("\n# Client certificate authentication")
  {
    config := curl.Request_Config{
      ssl_verify = .Both,
      ssl = &curl.SSL_Config{
        client_cert = "/path/to/client-cert.pem",
        client_key = "/path/to/client-key.pem",
        key_password = "optional-key-password",
      },
    }

    // Requires server that accepts client certificates
    res := curl.get("https://client-auth-required.com", config)
    defer curl.destroy_response(&res)
  }
  */

  /* Example configuration for custom CA certificate
  fmt.println("\n# Custom CA certificate")
  {
    config := curl.Request_Config{
      ssl_verify = .Both,
      ssl = &curl.SSL_Config{
        ca_file = "/path/to/custom/cacert.pem",
      },
    }

    // Requires server using custom CA
    res := curl.get("https://internal-server.com", config)
    defer curl.destroy_response(&res)
  }
  */
}
