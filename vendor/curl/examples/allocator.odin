package examples

import "core:fmt"
import "core:mem"
import curl "../"

main :: proc() {
  if !curl.init() {
    fmt.eprintln("Failed to initialize curl")
    return
  }
  defer curl.cleanup()

  track: mem.Tracking_Allocator
  mem.tracking_allocator_init(&track, context.allocator)
  defer {
    if len(track.allocation_map) > 0 {
      fmt.eprintln("\nAllocations still tracked:")
      for _, entry in track.allocation_map {
        fmt.eprintf("- Size: %d bytes @ %v\n", entry.size, entry.location)
      }
    }
    mem.tracking_allocator_destroy(&track)
  }

  config := curl.Request_Config{
    allocator = mem.tracking_allocator(&track),
  }

  {
    res := curl.get("https://httpbin.org/get", config)
    defer curl.destroy_response(&res)

    if res.error != .None {
      fmt.eprintln("Request failed:", curl.error_string(res.error))
      return
    }

    fmt.println("Response:", string(res.body))
  }

}
