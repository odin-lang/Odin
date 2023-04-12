package http

import "core:strconv"
import "core:strings"
import "core:fmt"
import "core:runtime"

Uri :: struct {
    _buf:      [dynamic]u8,
	scheme:    string,
	authority: Authority,
	path:      Path,
	query:     Query,
	fragment:  string,
}
Authority :: struct {
    userinfo: string,
    host: string,
    port: string, // Maybe(int) (?)
}

Path :: []string // TODO: is Path::[dynamic]string better for collapsing relative paths & inserting in req,res?

Query :: map[string]string

encode_uri :: proc(uri: ^Uri, allocator := context.allocator) -> string {
    using strings
    sb:= builder_make_len_cap(0, len(uri._buf), allocator)

    write_string(&sb,uri.scheme)
    write_string(&sb,"://")

    if len(uri.authority.userinfo) > 0 {
        write_string(&sb,uri.authority.userinfo)
        write_string(&sb,"@")
    }
    write_string(&sb,uri.authority.host)
    if len(uri.authority.port) > 0 {
        write_string(&sb, ":")
        write_string(&sb, uri.authority.port)
    }
    // write_string(&sb, "/")

    for p in uri.path {
        write_string(&sb, "/")
        write_string(&sb, p)
    }

    if uri.query != nil { write_string(&sb, "?") }
    i:=0
    for k, v in uri.query {
        if i > 0 { write_string(&sb, "&") }
        write_string(&sb, k)
        write_string(&sb, "=")
        write_string(&sb, v)
        i+=1
    }

    if len(uri.fragment) > 0 {
        write_string(&sb, "#")
        write_string(&sb, uri.fragment) 
    }

    return to_string(sb)
}

destroy_uri::proc(uri: ^Uri) {
    delete(uri._buf)
    delete(uri.path)
    delete_map(uri.query)
}

parse_uri :: proc(str: string, allocator := context.allocator) -> (uri: Uri, ok: bool = true) {
	context.allocator=allocator
    using strings
    _uri := _parse_uri_to_parts(str)
	uri = {}
    sb:= builder_make_len_cap(0, len(str), allocator)
    defer if !ok { builder_destroy(&sb) }

    write_string(&sb, _uri.str[_uri.scheme.from:_uri.scheme.til])
	uri.scheme = string(sb.buf[:]) // First string in buf so can just write it

	auth, aok := _parse_authority(_uri.str[_uri.authority.from:_uri.authority.til])
	if !aok {ok = false; return}
	uri.authority = auth
    ui, _ := percent_decode(&sb, uri.authority.userinfo)
    uri.authority.userinfo = ui
    host, _ := percent_decode(&sb, uri.authority.host)
    uri.authority.host = host

	path := _parse_path(_uri.str[_uri.path.from:_uri.path.til], allocator)
    defer if !ok { delete(uri._buf) }
	uri.path = path
    for pe, i in &uri.path {
        pd, _ := percent_decode(&sb, pe)
        uri.path[i] = pd
    }

	query, qok := _parse_query(_uri.str[_uri.query.from:_uri.query.til], allocator)
    defer if !ok { delete(uri._buf) }
	if !qok { ok = false; return	}
	uri.query = query

    for k, v in &uri.query {
        key, _ := percent_decode(&sb, k)
        value, _ := percent_decode(&sb, v)
        delete_key(&uri.query, k)
        uri.query[key] = value
    }

    frag, _ := percent_decode(&sb, _uri.str[_uri.fragment.from:_uri.fragment.til])
	uri.fragment = frag

    uri._buf = sb.buf
	return
}

//
Span :: struct {
	from: int,
	til:  int,
}
_uri :: struct {
	str:       string,
	scheme:    Span,
	authority: Span,
	path:      Span,
	query:     Span,
	fragment:  Span,
}
// Parses an Encoded URI into its major parts, does not subdivide into subparts (eg port on Authority)  
// Expects the uri to be octet encoded at this stage
_parse_uri_to_parts :: proc(uri: string) -> _uri {
	UriParseState :: enum {
        Scheme,
        Authority,
        Path,
        Query,
        Fragment,
    }
    state := UriParseState.Scheme
	uri_parts := _uri{}
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
// `auth_str` is expected to be the authority substring of a uri  
// An invalid port may cause parse failure
_parse_authority :: proc(auth_str: string) -> (auth: Authority, ok: bool = true) {
	auth = Authority{}
	AuthorityParts :: enum {
		UserInfo,
		Host,
		Port,
	}
	state := AuthorityParts.UserInfo
	part_start := 0

	loop: for i := 0; i < len(auth_str); i += 1 {
		c := auth_str[i]
		switch state {
		case .UserInfo:
			if c == '@' {
				state = .Host
				auth.userinfo = auth_str[part_start:i]
				part_start = i + 1
			}
		case .Host:
			if c == ':' {
				state = .Port
				auth.host = auth_str[part_start:i]
				part_start = i + 1
			}
		case .Port:
			if c == '/' {
				ok = false
				break loop
			}
		}
	}
	if ok {
		// Final check:
		switch state {
		case .UserInfo:
			auth.host = auth_str
		case .Host:
			auth.host = auth_str[part_start:]
		case .Port:
			auth.port = auth_str[part_start:]
		}
	}

	return auth, ok
}
// Allocates the array containing the str.
_parse_path :: proc(str: string, allocator := context.allocator) -> (path: Path) {
	path = strings.split(str, "/", allocator)
	return
}
// Always allocates the map
_parse_query :: proc(str: string, allocator := context.allocator) -> (query: Query, ok:bool=true) {
	key: string
	value: string
	on_key := true
	part_start := 0
    alloc_ok:runtime.Allocator_Error
	query,alloc_ok = make_map(map[string]string, 4, allocator)
    if alloc_ok != .None {ok=false;return}
	for i := 0; i < len(str); i += 1 {
		c := str[i]
		if c == '=' {
			if !on_key{ ok=false;return}
			on_key = !on_key
			key = str[part_start:i]
			part_start = i + 1
		} else if c == '&' {
            if on_key{ ok=false;return}
			on_key = !on_key
			value = str[part_start:i]
			part_start = i + 1

			query[key] = value
		}
	}
	if !on_key {
		value = str[part_start:]
		query[key] = value
	}
	return
}
///

import "core:testing"
import "core:net"
@(test)
test_parse_uri_to_parts :: proc(t: ^testing.T) {
    fmt.println("Baseline Example:")
    example_uri := "http://user:deprecated@example.com:4242/path/to/the/../resource?query=value#fragment"
    uri, ok := parse_uri(example_uri)
    euri:=encode_uri(&uri)
    fmt.println("parsed: ",uri.scheme, uri.authority.userinfo,uri.authority.host,uri.authority.port, uri.path, uri.query, uri.fragment)
    fmt.println("core:net", net.split_url(example_uri))
    fmt.println("encode: ", euri)
    fmt.println("RFC Example:")
    example_uri =  "ftp://cnn.example.com&story=breaking_news@10.0.0.1/top_story.htm?foo=3#bar"
    uri, ok = parse_uri(example_uri)
    euri = encode_uri(&uri)
    fmt.println("parsed: ",uri.scheme, uri.authority.userinfo,uri.authority.host,uri.authority.port, uri.path, uri.query, uri.fragment)
    fmt.println("core:net", net.split_url(example_uri))
    fmt.println("encode: ", euri)
}
