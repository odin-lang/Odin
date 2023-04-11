package http

Uri :: struct {
	scheme:    Scheme,
	authority: Authority,
	path:      Path,
	query:     Query,
	fragment:  string,
}
Authority :: struct {
    userinfo: string,
    host: string,
    port: Maybe(int), // string (?)
}
Path :: []string // todo: strip delimiters (/) and keep as []string, or retain as string

Query :: map[string]string

Scheme :: enum {
	HTTP,
	FTP,
	// FILE,
	// ...
}

//
@(private)
Span :: struct {
	from: int,
	til:  int,
}
@(private)
_URI :: struct {
	str:       string,
	scheme:    Span,
	authority: Span,
	path:      Span,
	query:     Span,
	fragment:  Span,
}
@(private)
UriParseState :: enum {
	Scheme,
	Authority,
	Path,
	Query,
	Fragment,
}
@(private)
// Parses an Encoded URI into its major parts, does not subdivide into subparts (eg port on Authority)  
// Expects the uri to be octet encoded at this stage
parse_uri_to_parts :: proc(uri: string) -> _URI {
	state := UriParseState.Scheme
	uri_parts := _URI{}
	uri_parts.str = uri
	part_start := 0

	state_loop: for i := 0; i < len(uri); i += 1 {
		c := uri[i]

		switch state {
		case .Scheme:
			if c == ':' {
				uri_parts.scheme = Span{part_start, i}
				part_start = i + 1
				state = .Authority
				if len(uri) - i >= 2 {
					if uri[i + 1] == '/' && uri[i + 2] == '/' {
						i += 2
						part_start += 2
					}
				}
			}
		case .Authority:
			if c == '/' {
				uri_parts.authority = Span{part_start, i}
				part_start = i + 1
				state = .Path
			}
		case .Path:
			if c == '?' {
				uri_parts.path = Span{part_start, i}
				part_start = i + 1
				state = .Query
			} else if c == '#' {
				uri_parts.path = Span{part_start, i}
				part_start = i + 1
				state = .Fragment
			}
		case .Query:
			if c == '#' {
				uri_parts.query = Span{part_start, i}
				part_start = i + 1
				state = .Fragment
			}
		case .Fragment:
		// Do nothing
		}
	}
	// Collect remaining from exited state:
	#partial switch state {
	case .Authority:
		uri_parts.authority = Span{part_start, len(uri)}
	case .Path:
		uri_parts.path = Span{part_start, len(uri)}
	case .Query:
		uri_parts.query = Span{part_start, len(uri)}
	case .Fragment:
		uri_parts.fragment = Span{part_start, len(uri)}
	}

	return uri_parts
}

///

import "core:testing"
import "core:fmt"
@(test)
test_parse_uri_to_parts :: proc(t: ^testing.T) {
    example_uri := "http://user:deprecated@example.com:4242/path/to/the/../resource?query=value#fragment"
	uri := parse_uri_to_parts(example_uri)
    fmt.println("Original URI:", example_uri)
	fmt.println("Scheme      :", uri.str[uri.scheme.from:uri.scheme.til])
	fmt.println("Authority   :", uri.str[uri.authority.from:uri.authority.til])
	fmt.println("Path        :", uri.str[uri.path.from:uri.path.til])
	fmt.println("Query       :", uri.str[uri.query.from:uri.query.til])
	fmt.println("Fragment    :", uri.str[uri.fragment.from:uri.fragment.til])

    example_uri =  "ftp://cnn.example.com&story=breaking_news@10.0.0.1/top_story.htm?foo=3#bar"
	uri = parse_uri_to_parts(example_uri)
    fmt.println("Original URI:", example_uri)
	fmt.println("Scheme      :", uri.str[uri.scheme.from:uri.scheme.til])
	fmt.println("Authority   :", uri.str[uri.authority.from:uri.authority.til])
	fmt.println("Path        :", uri.str[uri.path.from:uri.path.til])
	fmt.println("Query       :", uri.str[uri.query.from:uri.query.til])
	fmt.println("Fragment    :", uri.str[uri.fragment.from:uri.fragment.til])
}
