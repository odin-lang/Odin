package http

import "core:strconv"
import "core:strings"
import "core:fmt"
import "core:runtime"

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

Path :: []string // TODO: is Path::[dynamic]string better for collapsing relative paths & inserting in req,res?

Query :: map[string]string

Scheme :: enum {
    Invalid,
	HTTP,
	FTP,
	// FILE,
	// ...
}


// TODO: the delete-unwind seems unwieldy, probably should revisit design of how to allocate.
// TODO: need a means of cleaning up & tracking who needs deleted
parse_uri :: proc(str: string, allocator := context.allocator) -> (uri: Uri, ok: bool = true) {
	context.allocator=allocator
    _uri := _parse_uri_to_parts(str)
	uri = {}

	scheme, sok := _parse_scheme(_uri.str[_uri.scheme.from:_uri.scheme.til])
	if !sok {return uri, false}
	uri.scheme = scheme

	auth, aok := _parse_authority(_uri.str[_uri.authority.from:_uri.authority.til])
	if !aok {return uri, false}
	uri.authority = auth
    userinfo,uok:=decode_octet(uri.authority.userinfo)
	if !uok {
        if len(userinfo)>0 {delete(userinfo)}
        return uri, false

    }
    host,hok:=decode_octet(uri.authority.host)
	if !hok {
        if len(userinfo)>0 {delete(userinfo)}
        if len(host)>0 {delete(host)}
        return uri, false
    }
    uri.authority.userinfo = userinfo
    uri.authority.host = host

	path := _parse_path(_uri.str[_uri.path.from:_uri.path.til])
	uri.path = path
    for pe,i in &uri.path {
        pd, pok:=decode_octet(pe)
        assert(pok) // TODO: definitely work out better deallocation strategy
        uri.path[i]=pd
    }

	query, qok := _parse_query(_uri.str[_uri.query.from:_uri.query.til])
	if !qok {
		if query != nil {delete_map(query)}
		if path != nil {delete(path)}
		return uri, false
	}
	uri.query = query

    for k,v in &uri.query{
        key, kok := decode_octet(k)
        value, vok := decode_octet(v)
        assert(kok&&vok)
        delete_key(&uri.query,k)
        uri.query[key]=value
    }

    frag, fok := decode_octet(_uri.str[_uri.fragment.from:_uri.fragment.til])
    assert(fok)
	uri.fragment = frag

	return
}

//
// @(private)
Span :: struct {
	from: int,
	til:  int,
}
// @(private)
_URI :: struct {
	str:       string,
	scheme:    Span,
	authority: Span,
	path:      Span,
	query:     Span,
	fragment:  Span,
}
// @(private)
// Parses an Encoded URI into its major parts, does not subdivide into subparts (eg port on Authority)  
// Expects the uri to be octet encoded at this stage
_parse_uri_to_parts :: proc(uri: string) -> _URI {
	UriParseState :: enum {
        Scheme,
        Authority,
        Path,
        Query,
        Fragment,
    }
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
			auth.port, ok = strconv.parse_int(auth_str[part_start:])
		}
	}

	return auth, ok
}
// TODO: this is wasteful, enums could all be lowercase, or make case invarint version of enum_to_str
// fails on bad parse, or unsupported Scheme
_parse_scheme :: proc(str: string) -> (scheme: Scheme, ok: bool = true) {
	upper_str := strings.to_upper(str)
	scheme, ok = fmt.string_to_enum_value(Scheme, upper_str)
	if !ok {scheme = .Invalid}
	return
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
	query,alloc_ok = make_map(map[string]string, 8, allocator)
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
@(test)
test_parse_uri_to_parts :: proc(t: ^testing.T) {
    example_uri := "http://user:deprecated@example.com:4242/path/to/the/../resource?query=value#fragment"
	uri := _parse_uri_to_parts(example_uri)
    fmt.println("Original URI:", example_uri)
	fmt.println("Scheme      :", uri.str[uri.scheme.from:uri.scheme.til])
	fmt.println("Authority   :", uri.str[uri.authority.from:uri.authority.til])
	fmt.println("Path        :", uri.str[uri.path.from:uri.path.til])
	fmt.println("Query       :", uri.str[uri.query.from:uri.query.til])
	fmt.println("Fragment    :", uri.str[uri.fragment.from:uri.fragment.til])

    example_uri =  "ftp://cnn.example.com&story=breaking_news@10.0.0.1/top_story.htm?foo=3#bar"
	uri = _parse_uri_to_parts(example_uri)
    fmt.println("Original URI:", example_uri)
	fmt.println("Scheme      :", uri.str[uri.scheme.from:uri.scheme.til])
	fmt.println("Authority   :", uri.str[uri.authority.from:uri.authority.til])
	fmt.println("Path        :", uri.str[uri.path.from:uri.path.til])
	fmt.println("Query       :", uri.str[uri.query.from:uri.query.til])
	fmt.println("Fragment    :", uri.str[uri.fragment.from:uri.fragment.til])
}
