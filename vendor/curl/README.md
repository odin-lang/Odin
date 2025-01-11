# odin-curl

A minimal libcurl binding for the Odin programming language.

## Requirements

- Odin compiler
- libcurl development files
  - Ubuntu/Debian: `sudo apt install libcurl4-dev`
  - Fedora: `sudo dnf install libcurl-devel`
  - macOS: `brew install curl`
  - Windows: Download from [curl](https://curl.se/windows/)

## Usage

```odin
package main

import "core:fmt"
import curl "vendor:curl"

main :: proc() {
    if !curl.init() {
        fmt.eprintln("Failed to initialize curl")
        return
    }
    defer curl.cleanup()

    config := curl.Request_Config{
        headers = []string{
            "User-Agent: odin-curl/0.1",
        },
    }

    res := curl.get("https://httpbin.org/json", config)
    defer curl.destroy_response(&res)

    if res.error != .None {
        fmt.eprintln("Request failed:", curl.error_string(res.error))
        return
    }

    fmt.println("Response:", string(res.body))
}
```

## Examples

Check the `examples/` directory for:
- Basic GET and POST requests
- JSON handling with type-safe responses
- Custom response parsing
- SSL/TLS configuration
- Memory allocation tracking

## Version Compatibility

This binding is based on curl.h version 8.11.1.

## License

ISC. See the [LICENSE](LICENSE) file for details.

Copyright (c) 2024-2025 Zoltán Kéri <z@zolk3ri.name>

## Credits

- libcurl - https://curl.se/libcurl/
- Odin Programming Language - https://odin-lang.org/
