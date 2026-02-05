package tests_bifrost

import "core:bytes"
import "core:strings"
import "core:testing"
import http "vendor:bifrost/http"

HTTP_Version_Test :: struct {
	vers: string,
	major: int,
	minor: int,
	ok: bool,
}

parse_http_version_tests := []HTTP_Version_Test{
	{vers = "HTTP/0.0", major = 0, minor = 0, ok = true},
	{vers = "HTTP/0.9", major = 0, minor = 9, ok = true},
	{vers = "HTTP/1.0", major = 1, minor = 0, ok = true},
	{vers = "HTTP/1.1", major = 1, minor = 1, ok = true},
	{vers = "HTTP", major = 0, minor = 0, ok = false},
	{vers = "HTTP/one.one", major = 0, minor = 0, ok = false},
	{vers = "HTTP/1.1/", major = 0, minor = 0, ok = false},
	{vers = "HTTP/-1,0", major = 0, minor = 0, ok = false},
	{vers = "HTTP/0,-1", major = 0, minor = 0, ok = false},
	{vers = "HTTP/", major = 0, minor = 0, ok = false},
	{vers = "HTTP/1,1", major = 0, minor = 0, ok = false},
	{vers = "HTTP/+1.1", major = 0, minor = 0, ok = false},
	{vers = "HTTP/1.+1", major = 0, minor = 0, ok = false},
	{vers = "HTTP/0000000001.1", major = 0, minor = 0, ok = false},
	{vers = "HTTP/1.0000000001", major = 0, minor = 0, ok = false},
	{vers = "HTTP/3.14", major = 0, minor = 0, ok = false},
	{vers = "HTTP/12.3", major = 0, minor = 0, ok = false},
}

@(test)
test_parse_http_version :: proc(t: ^testing.T) {
	for tt in parse_http_version_tests {
		major, minor, ok := http.parse_http_version(tt.vers)
		ev(t, ok, tt.ok)
		if ok {
			ev(t, major, tt.major)
			ev(t, minor, tt.minor)
		}
	}
}

Basic_Auth_Test :: struct {
	username: string,
	password: string,
	ok: bool,
}

basic_auth_tests := []Basic_Auth_Test{
	{username = "Aladdin", password = "open sesame", ok = true},
	{username = "Aladdin", password = "open:sesame", ok = true},
	{username = "", password = "", ok = true},
}

@(test)
test_request_basic_auth :: proc(t: ^testing.T) {
	for tt in basic_auth_tests {
		req := http.Request{}
		ok_set := http.request_set_basic_auth(&req, tt.username, tt.password)
		ev(t, ok_set, true)
		user, pass, ok := http.request_basic_auth(&req)
		ev(t, ok, tt.ok)
		ev(t, user, tt.username)
		ev(t, pass, tt.password)
	}

	req := http.Request{}
	user, pass, ok := http.request_basic_auth(&req)
	ev(t, ok, false)
	ev(t, user, "")
	ev(t, pass, "")
}

Parse_Basic_Auth_Test :: struct {
	header: string,
	username: string,
	password: string,
	ok: bool,
}

parse_basic_auth_tests := []Parse_Basic_Auth_Test{
	{header = "Basic QWxhZGRpbjpvcGVuIHNlc2FtZQ==", username = "Aladdin", password = "open sesame", ok = true},
	{header = "BASIC QWxhZGRpbjpvcGVuIHNlc2FtZQ==", username = "Aladdin", password = "open sesame", ok = true},
	{header = "basic QWxhZGRpbjpvcGVuIHNlc2FtZQ==", username = "Aladdin", password = "open sesame", ok = true},
	{header = "Basic QWxhZGRpbjpvcGVuOnNlc2FtZQ==", username = "Aladdin", password = "open:sesame", ok = true},
	{header = "Basic Og==", username = "", password = "", ok = true},
	{header = "BasicQWxhZGRpbjpvcGVuIHNlc2FtZQ==", username = "", password = "", ok = false},
	{header = "QWxhZGRpbjpvcGVuIHNlc2FtZQ==", username = "", password = "", ok = false},
	{header = "Basic ", username = "", password = "", ok = false},
	{header = "Basic Aladdin:open sesame", username = "", password = "", ok = false},
	{header = `Digest username="Aladdin"`, username = "", password = "", ok = false},
}

@(test)
test_request_parse_basic_auth :: proc(t: ^testing.T) {
	for tt in parse_basic_auth_tests {
		req := http.Request{Header = http.Header{"Authorization" = []string{tt.header}}}
		user, pass, ok := http.request_basic_auth(&req)
		ev(t, ok, tt.ok)
		ev(t, user, tt.username)
		ev(t, pass, tt.password)
	}
}

Read_Request_Test :: struct {
	raw: string,
	status: int,
	header: http.Header,
}

read_request_tests := []Read_Request_Test{
	{
		raw = "GET / HTTP/1.1\r\nheader:foo\r\n\r\n",
		status = 0,
		header = http.Header{"Header" = []string{"foo"}},
	},
	{
		raw = "POST / HTTP/1.1\r\nContent-Length: 10\r\nContent-Length: 0\r\n\r\nGopher hey\r\n",
		status = http.Status_Bad_Request,
	},
	{
		raw = "PUT / HTTP/1.1\r\nContent-Length: 6 \r\nContent-Length: 6\r\nContent-Length:6\r\n\r\nGopher\r\n",
		status = 0,
		header = http.Header{"Content-Length" = []string{"6"}},
	},
	{
		raw = "HEAD / HTTP/1.1\r\nHost: foo\r\nHost: bar\r\n\r\n\r\n\r\n",
		status = http.Status_Bad_Request,
	},
}

header_equal :: proc(t: ^testing.T, got, want: http.Header) {
	if want == nil {
		ev(t, got == nil || len(got) == 0, true)
		return
	}
	ev(t, len(got), len(want))
	for key, vals in want {
		gvals, ok := http.header_values(got, key)
		ev(t, ok, true)
		ev(t, len(gvals), len(vals))
		for i in 0..<len(vals) {
			ev(t, gvals[i], vals[i])
		}
	}
}

@(test)
test_request_parse :: proc(t: ^testing.T) {
	for tt in read_request_tests {
		req, status := http.request_parse(tt.raw)
		ev(t, status, tt.status)
		if status == 0 {
			header_equal(t, req.Header, tt.header)
		}
		if req.Body != nil {
			delete(req.Body)
		}
		http.header_reset(&req.Header)
		http.header_free_string(req.Method)
		http.header_free_string(req.Target)
		http.header_free_string(req.Proto)
	}
}

@(test)
test_request_write_basic :: proc(t: ^testing.T) {
	req := http.Request{
		Method = "GET",
		Target = "/",
		Proto = "HTTP/1.1",
		Header = http.Header{
			"Host" = []string{"foo.com"},
			"User-Agent" = []string{"Bifrost"},
		},
	}
	var buf bytes.Buffer
	bytes.buffer_init_allocator(&buf, 0, 256)
	ok := http.request_write(&buf, &req, true)
	ev(t, ok, true)
	got := string(bytes.buffer_to_bytes(&buf))
	want := "GET / HTTP/1.1\r\nHost: foo.com\r\nUser-Agent: Bifrost\r\n\r\n"
	ev(t, got, want)
	bytes.buffer_destroy(&buf)
}

@(test)
test_request_write_sanitizes :: proc(t: ^testing.T) {
	req := http.Request{
		Method = "GET",
		Target = "/after",
		Proto = "HTTP/1.1",
		Header = http.Header{
			"Host" = []string{"foo"},
			"User-Agent" = []string{"evil\r\nX-Evil: evil"},
		},
	}
	var buf bytes.Buffer
	bytes.buffer_init_allocator(&buf, 0, 256)
	ok := http.request_write(&buf, &req, true)
	ev(t, ok, true)
	got := string(bytes.buffer_to_bytes(&buf))
	ev(t, strings.contains(got, "User-Agent: evil  X-Evil: evil\r\n"), true)
	bytes.buffer_destroy(&buf)
}
