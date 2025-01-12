package examples

import "base:runtime"
import "core:fmt"
import "core:encoding/json"
import "core:mem"
import "core:strings"
import curl "../"

Post :: struct {
  id: int,
  title: string,
  body: string,
  userId: int,
}

Comment :: struct {
  postId: int,
  id: int,
  name: string,
  email: string,
  body: string,
}

Line_Count :: struct {
  count: int,
  lines: []string,
}

destroy_line_count :: proc(lc: ^Line_Count, allocator: runtime.Allocator) {
  if lc == nil do return
  for s in lc.lines {
    delete(s, allocator)
  }
  delete(lc.lines, allocator)
}

main :: proc() {
  if !curl.init() {
    fmt.eprintln("Failed to initialize curl")
    return
  }
  defer curl.cleanup()

  track: mem.Tracking_Allocator
  mem.tracking_allocator_init(&track, context.allocator)
  allocator := mem.tracking_allocator(&track)
  defer mem.tracking_allocator_destroy(&track)

  config := curl.Request_Config{
    allocator = allocator,
    headers = []string{
      "Accept: application/json",
      "Content-Type: application/json",
    },
  }

  {
    fmt.println("\n# GET with string response:")
    res := curl.get_string("https://httpbin.org/json", config)
    defer curl.destroy_response(&res)

    if res.error != .None {
      fmt.eprintln("Request failed:", curl.error_string(res.error))
      return
    }

    fmt.printf("Status: %d\nBody: %s\n", res.status_code, res.body)
  }

  {
    fmt.println("\n# GET with JSON response:")
    res := curl.get_json(Post, "https://jsonplaceholder.typicode.com/posts/1", config)
    defer curl.destroy_response(&res)

    if res.error != .None {
      fmt.eprintln("Request failed:", curl.error_string(res.error))
      return
    }

    fmt.printf("Post %d: %q\n", res.body.id, res.body.title)
  }

  {
    fmt.println("\n# GET with custom parser:")

    line_counter := curl.Parser(Line_Count){
      parse = proc(data: []byte, allocator: runtime.Allocator, err: ^curl.Error) -> Line_Count {
        if len(data) == 0 {
          return Line_Count{}
        }

        text := string(data)
        lines := strings.split(text, "\n", allocator)
        if lines == nil {
          err^ = .Bad_Content_Encoding
          return Line_Count{}
        }
        defer delete(lines, allocator)

        non_empty := 0
        for line in lines {
          if strings.trim_space(line) != "" {
            non_empty += 1
          }
        }

        result := Line_Count{
          count = non_empty,
          lines = make([]string, non_empty, allocator),
        }

        i := 0
        for line in lines {
          if trimmed := strings.trim_space(line); trimmed != "" {
            result.lines[i] = strings.clone(trimmed, allocator)
            i += 1
          }
        }

        return result
      },
    }

    res := curl.get_with(Line_Count,
                         "https://httpbin.org/robots.txt",
                         line_counter,
                         config)
    defer {
      destroy_line_count(&res.body, allocator)
      curl.destroy_response(&res)
    }

    if res.error != .None {
      fmt.eprintln("Request failed:", curl.error_string(res.error))
      return
    }

    fmt.printf("Found %d non-empty lines:\n", res.body.count)
    for line, i in res.body.lines {
      fmt.printf("%d: %s\n", i+1, line)
    }
  }

  {
    fmt.println("\n# POST with string response:")
    body := "Hello Server!"
    res := curl.post_string("https://httpbin.org/post", body, config)
    defer curl.destroy_response(&res)

    if res.error != .None {
      fmt.eprintln("Request failed:", curl.error_string(res.error))
      return
    }

    fmt.printf("Status: %d\nResponse: %s\n", res.status_code, res.body)
  }

  {
    fmt.println("\n# POST with JSON response:")
    new_comment := Comment{
      postId = 1,
      name = "Test Comment",
      email = "test@example.com",
      body = "This is a test comment",
    }

    data, marshal_err := json.marshal(new_comment, allocator=allocator)
    if marshal_err != nil {
      fmt.eprintln("JSON marshal failed:", marshal_err)
      return
    }
    defer delete(data)

    res := curl.post_json(Comment,
                          "https://jsonplaceholder.typicode.com/comments",
                          string(data),
                          config)
    defer curl.destroy_response(&res)

    if res.error != .None {
      fmt.eprintln("Request failed:", curl.error_string(res.error))
      return
    }

    fmt.printf("Created comment: ID %d for post %d\n",
               res.body.id, res.body.postId)
    fmt.printf("Comment text: %s\n", res.body.body)
  }

  {
    fmt.println("\n# POST with custom parser:")

    line_counter := curl.Parser(Line_Count){
      parse = proc(data: []byte, allocator: runtime.Allocator, err: ^curl.Error) -> Line_Count {
        if len(data) == 0 {
          return Line_Count{}
        }

        text := string(data)
        lines := strings.split(text, "\n", allocator)
        if lines == nil {
          err^ = .Bad_Content_Encoding
          return Line_Count{}
        }
        defer delete(lines, allocator)

        non_empty := 0
        for line in lines {
          if strings.trim_space(line) != "" {
            non_empty += 1
          }
        }

        result := Line_Count{
          count = non_empty,
          lines = make([]string, non_empty, allocator),
        }

        i := 0
        for line in lines {
          if trimmed := strings.trim_space(line); trimmed != "" {
            result.lines[i] = strings.clone(trimmed, allocator)
            i += 1
          }
        }

        return result
      },
    }

    post_data := "Hello\n\nWorld\n"
    res := curl.post_with(Line_Count,
                          "https://httpbin.org/post",
                          post_data,
                          line_counter,
                          config)
    defer {
      destroy_line_count(&res.body, allocator)
      curl.destroy_response(&res)
    }

    if res.error != .None {
      fmt.eprintln("Request failed:", curl.error_string(res.error))
      return
    }

    fmt.printf("Found %d non-empty lines in POST response:\n", res.body.count)
    for line, i in res.body.lines {
      fmt.printf("%d: %s\n", i+1, line)
    }
  }
}
