package examples

import "core:fmt"
import "core:time"
import curl "../"

main :: proc() {
  if !curl.init() {
    fmt.eprintln("Failed to initialize curl")
    return
  }
  defer curl.cleanup()

  // Simple GET with custom User-Agent
  get_config := curl.Request_Config{
    headers = []string{
      "User-Agent: odin-curl/0.1",
    },
    verbose = true,
  }

  get_res := curl.get("https://httpbin.org/get", get_config)
  defer curl.destroy_response(&get_res)

  if get_res.error != .None {
    fmt.eprintln("Request failed with error:", curl.error_string(get_res.error))
    return
  }

  fmt.println("Response Status:", get_res.status_code)
  fmt.println("Body:", string(get_res.body))

  // Example POST request
  post_config := curl.Request_Config{
    headers = []string{
      "User-Agent: odin-curl/0.1",
      "Content-Type: application/json",
    },
  }

  post_data := `{"test": "data"}`
  post_res := curl.post("https://httpbin.org/post", post_data, post_config)
  defer curl.destroy_response(&post_res)

  if post_res.error != .None {
    fmt.eprintln("POST request failed with error:", curl.error_string(post_res.error))
    return
  }

  fmt.println("\nPOST Response Status:", post_res.status_code)
  fmt.println("POST Body:", string(post_res.body))

  // Request with short timeout to delayed response server
  {
    timeout_config := curl.Request_Config{
      timeout = 1 * time.Second,
    }

    timeout_res := curl.get("https://httpbin.org/delay/5", timeout_config)
    defer curl.destroy_response(&timeout_res)

    if timeout_res.error == .Operation_Timedout {
      fmt.println("Request timed out as expected after 1 second")
    } else {
      fmt.eprintln("Expected timeout error, got:", curl.error_string(timeout_res.error))
    }
  }

  // Request with sufficient timeout
  {
    delayed_config := curl.Request_Config{
      timeout = 3 * time.Second,
    }

    delayed_res := curl.get("https://httpbin.org/delay/1", delayed_config)
    defer curl.destroy_response(&delayed_res)

    if delayed_res.error != .None {
      fmt.eprintln("Request failed:", curl.error_string(delayed_res.error))
      return
    }

    fmt.println("Request completed within timeout")
    fmt.println("Response Status:", delayed_res.status_code)
  }

  // Test redirect following
  redirect_config := curl.Request_Config{
    follow_location = true,
    max_redirects = 5,
  }
  redirect_res := curl.get("http://httpbin.org/redirect/3", redirect_config)
  defer curl.destroy_response(&redirect_res)

  if redirect_res.error == .None {
    fmt.println("Successfully followed redirects")
    fmt.println("Response:", string(redirect_res.body))
  } else {
    fmt.eprintln("Failed to follow redirects:", curl.error_string(redirect_res.error))
  }

  // Test max redirects limit
  max_redirect_config := curl.Request_Config{
    follow_location = true,
    max_redirects = 2, // Set limit lower than number of redirects
  }
  max_redirect_res := curl.get("http://httpbin.org/redirect/3", max_redirect_config)
  defer curl.destroy_response(&max_redirect_res)

  if max_redirect_res.error == .Too_Many_Redirects {
    fmt.println("Max redirects limit worked as expected")
  } else {
    fmt.eprintln("Expected too many redirects, got:", curl.error_string(max_redirect_res.error))
  }
}
